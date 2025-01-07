// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {EscrowContract} from "../src/EscrowContract.sol";

contract TestEscrowContract is Test {
    EscrowContract escrowContract;

    address payable BUYER = payable(makeAddr("buyer"));
    address payable SELLER = payable(makeAddr("seller"));
    address payable ARBITRATOR = payable(makeAddr("arbitrator"));
    address RANDOM = makeAddr("random");

    function setUp() public {
        vm.prank(BUYER);
        escrowContract = new EscrowContract();

        // give buyer funds - 10 ETH
        deal(BUYER, 10e18);
    }

    function test_buyer_funds() public view {
        assertEq(address(BUYER).balance, 10e18);
    }

    // TEST CreateEscrow(address payable seller, address arbitrator)
    function test_createEscrow_success() public {
        vm.prank(BUYER);
        uint256 id = escrowContract.createEscrow{value: 1 ether}({seller: SELLER, arbitrator: ARBITRATOR});

        (
            address payable buyer,
            address payable seller,
            address arbitrator,
            uint256 amount,
            EscrowContract.EscrowStatus status
        ) = escrowContract.escrows(id);

        assertEq(buyer, BUYER, "Buyer address not set correctly");
        assertEq(seller, SELLER, "Seller address not set correctly");
        assertEq(arbitrator, ARBITRATOR, "Arbitrator address not set correctly");
        assertEq(amount, 1e18, "Value incorrectly saved");
        assertEq(uint8(status), uint8(EscrowContract.EscrowStatus.Pending), "Escrow status wrong");
    }

    function test_createEscrow_fail_InsufficientAmount() public {
        vm.prank(BUYER);
        vm.expectRevert(EscrowContract.EscrowContract__InsufficientAmount.selector);
        escrowContract.createEscrow{value: 0e18}({seller: SELLER, arbitrator: ARBITRATOR});
    }

    function test_event_createEscrow_EscrowCreated() public {
        vm.expectEmit(false, true, true, true);
        vm.prank(BUYER);
        emit EscrowContract.EscrowCreated(1, BUYER, SELLER, 1e18);
        escrowContract.createEscrow{value: 1e18}({seller: SELLER, arbitrator: ARBITRATOR});
    }

    // TEST releaseFunds(uint256 escrowId) onlyBuyer
    function test_releaseFunds_success() public {
        vm.startPrank(BUYER);
        uint256 id = escrowContract.createEscrow{value: 1e18}({seller: SELLER, arbitrator: ARBITRATOR});

        escrowContract.releaseFunds(id);

        (
            address payable buyer,
            address payable seller,
            address arbitrator,
            uint256 amount,
            EscrowContract.EscrowStatus status
        ) = escrowContract.escrows(id);

        assertEq(buyer, BUYER, "Buyer address not set correctly");
        assertEq(seller, SELLER, "Seller address not set correctly");
        assertEq(arbitrator, ARBITRATOR, "Arbitrator address not set correctly");
        assertEq(amount, 1e18, "Value incorrectly saved");
        assertEq(uint8(status), uint8(EscrowContract.EscrowStatus.Completed), "Escrow status wrong");

        assertEq(address(SELLER).balance, 1e18);
        console.log("Seller balance after funds are released", address(SELLER).balance);
    }

    function test_releaseFunds_fail_OnlyBuyerCanCall() public {
        vm.prank(BUYER);
        uint256 id = escrowContract.createEscrow{value: 1e18}({seller: SELLER, arbitrator: ARBITRATOR});
        vm.expectRevert(EscrowContract.EscrowContract__OnlyBuyerCanCall.selector);
        vm.prank(SELLER);
        escrowContract.releaseFunds(id);
    }

    function test_releaseFunds_fail_NotInAReleasableState() public {
        vm.prank(BUYER);
        uint256 id = escrowContract.createEscrow{value: 1e18}({seller: SELLER, arbitrator: ARBITRATOR});
        vm.prank(SELLER);
        escrowContract.raiseDispute(id);
        vm.expectRevert(EscrowContract.EscrowContract__NotInAReleasableState.selector);
        vm.prank(BUYER);
        escrowContract.releaseFunds(id);
    }

    function test_event_releaseFunds_FundsReleased() public {
        vm.startPrank(BUYER);
        uint256 id = escrowContract.createEscrow{value: 1e18}({seller: SELLER, arbitrator: ARBITRATOR});
        vm.expectEmit(false, true, false, true);
        emit EscrowContract.FundsReleased(1, SELLER);
        escrowContract.releaseFunds(id);
    }

    // TEST raiseDispute(uint256 escrowId) onlyParticipant
    function test_raiseDispute_success() public {
        vm.prank(BUYER);
        uint256 id = escrowContract.createEscrow{value: 1e18}({seller: SELLER, arbitrator: ARBITRATOR});
        vm.prank(SELLER);
        escrowContract.raiseDispute(id);

        (
            address payable buyer,
            address payable seller,
            address arbitrator,
            uint256 amount,
            EscrowContract.EscrowStatus status
        ) = escrowContract.escrows(id);

        assertEq(buyer, BUYER, "Buyer address not set correctly");
        assertEq(seller, SELLER, "Seller address not set correctly");
        assertEq(arbitrator, ARBITRATOR, "Arbitrator address not set correctly");
        assertEq(amount, 1e18, "Value incorrectly saved");
        assertEq(uint8(status), uint8(EscrowContract.EscrowStatus.Disputed), "Escrow status wrong");
    }

    function test_raiseDispute_fail_NotAuthorised() public {
        vm.prank(BUYER);
        uint256 id = escrowContract.createEscrow{value: 1e18}({seller: SELLER, arbitrator: ARBITRATOR});
        vm.expectRevert(EscrowContract.EscrowContract__NotAuthorised.selector);
        vm.prank(RANDOM);
        escrowContract.raiseDispute(id);
    }

    function test_raiseDispute_fail_NotDisputable() public {
        vm.prank(BUYER);
        uint256 id = escrowContract.createEscrow{value: 1e18}({seller: SELLER, arbitrator: ARBITRATOR});
        vm.prank(BUYER);
        escrowContract.releaseFunds(id);
        vm.expectRevert(EscrowContract.EscrowContract__NotDisputable.selector);
        vm.prank(SELLER);
        escrowContract.raiseDispute(id);

        (
            address payable buyer,
            address payable seller,
            address arbitrator,
            uint256 amount,
            EscrowContract.EscrowStatus status
        ) = escrowContract.escrows(id);

        assertEq(buyer, BUYER, "Buyer address not set correctly");
        assertEq(seller, SELLER, "Seller address not set correctly");
        assertEq(arbitrator, ARBITRATOR, "Arbitrator address not set correctly");
        assertEq(amount, 1e18, "Value incorrectly saved");
        assertEq(uint8(status), uint8(EscrowContract.EscrowStatus.Completed), "Escrow status wrong");
    }

    function test_event_raiseDispute_DisputeRaised() public {
        vm.prank(BUYER);
        uint256 id = escrowContract.createEscrow{value: 1e18}({seller: SELLER, arbitrator: ARBITRATOR});
        vm.expectEmit(false, true, false, true);
        vm.prank(SELLER);
        emit EscrowContract.DisputeRaised(1);
        escrowContract.raiseDispute(id);
    }

    // TEST resolveDispute(uint256 escrowId, bool releaseToSeller) onlyArbitrator
    function test_resolveDispute_success_BUYER() public {
        vm.prank(BUYER);
        uint256 id = escrowContract.createEscrow{value: 1e18}({seller: SELLER, arbitrator: ARBITRATOR});
        vm.prank(BUYER);
        escrowContract.raiseDispute(id);
        vm.prank(ARBITRATOR);
        escrowContract.resolveDispute(id, false);

        (
            address payable buyer,
            address payable seller,
            address arbitrator,
            uint256 amount,
            EscrowContract.EscrowStatus status
        ) = escrowContract.escrows(id);

        assertEq(buyer, BUYER, "Buyer address not set correctly");
        assertEq(seller, SELLER, "Seller address not set correctly");
        assertEq(arbitrator, ARBITRATOR, "Arbitrator address not set correctly");
        assertEq(amount, 1e18, "Value incorrectly saved");
        assertEq(uint8(status), uint8(EscrowContract.EscrowStatus.Resolved), "Escrow status wrong");

        assertEq(address(BUYER).balance, 10e18);
        console.log("Buyer balance after funds are released", address(BUYER).balance);
    }

    function test_resolveDispute_success_SELLER() public {
        vm.prank(BUYER);
        uint256 id = escrowContract.createEscrow{value: 1e18}({seller: SELLER, arbitrator: ARBITRATOR});
        vm.prank(SELLER);
        escrowContract.raiseDispute(id);
        vm.prank(ARBITRATOR);
        escrowContract.resolveDispute(id, true);

        (
            address payable buyer,
            address payable seller,
            address arbitrator,
            uint256 amount,
            EscrowContract.EscrowStatus status
        ) = escrowContract.escrows(id);

        assertEq(buyer, BUYER, "Buyer address not set correctly");
        assertEq(seller, SELLER, "Seller address not set correctly");
        assertEq(arbitrator, ARBITRATOR, "Arbitrator address not set correctly");
        assertEq(amount, 1e18, "Value incorrectly saved");
        assertEq(uint8(status), uint8(EscrowContract.EscrowStatus.Resolved), "Escrow status wrong");

        assertEq(address(SELLER).balance, 1e18);
        console.log("Seller balance after funds are released", address(SELLER).balance);
    }

    function test_resolveDispute_fail_OnlyArbitratorCanCall() public {
        vm.prank(BUYER);
        uint256 id = escrowContract.createEscrow{value: 1e18}({seller: SELLER, arbitrator: ARBITRATOR});
        vm.prank(SELLER);
        escrowContract.raiseDispute(id);
        vm.expectRevert(EscrowContract.EscrowContract__OnlyArbitratorCanCall.selector);
        vm.prank(SELLER);
        escrowContract.resolveDispute(id, true);
    }

    function test_resolveDispute_fail_NotInDispute() public {
        vm.prank(BUYER);
        uint256 id = escrowContract.createEscrow{value: 1e18}({seller: SELLER, arbitrator: ARBITRATOR});
        vm.expectRevert(EscrowContract.EscrowContract__NotInDispute.selector);
        vm.prank(ARBITRATOR);
        escrowContract.resolveDispute(id, true);
    }

    function test_event_resolveDispute_DisputeResolved() public {
        vm.prank(BUYER);
        uint256 id = escrowContract.createEscrow{value: 1e18}({seller: SELLER, arbitrator: ARBITRATOR});
        vm.prank(SELLER);
        escrowContract.raiseDispute(id);
        vm.expectEmit(false, true, false, true);
        emit EscrowContract.DisputeResolved(1, SELLER);
        vm.prank(ARBITRATOR);
        escrowContract.resolveDispute(id, true);
    }
}
