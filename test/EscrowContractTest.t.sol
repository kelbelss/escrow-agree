// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {EscrowContract} from "../src/EscrowContract.sol";

contract TestEscrowContract is Test {
    // test events
    // test errors
    // test each function with edge cases

    // change requires to reverts with errors

    EscrowContract escrowContract;

    address payable BUYER = payable(makeAddr("buyer"));
    address payable SELLER = payable(makeAddr("seller"));
    address payable ARBITRATOR = payable(makeAddr("arbitrator"));

    function setUp() public {
        vm.prank(BUYER);
        escrowContract = new EscrowContract();

        // give buyer funds - 10 ETH
        deal(BUYER, 10e18);
    }

    function test_buyer_funds() public {
        assertEq(address(BUYER).balance, 10e18);
    }

    // fail/error, success, event - consider checking enum status changes

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
        assertEq(amount, 1 ether, "Value incorrectly saved");
        assertEq(uint8(status), uint8(EscrowContract.EscrowStatus.Pending), "Escrow status wrong");
    }

    function test_createEscrow_fail_InsufficientAmount() public {}
    function test_event_createEscrow_EscrowCreated() public {}

    // TEST releaseFunds(uint256 escrowId) onlyBuyer
    function test_releaseFunds_success() public {}
    function test_releaseFunds_fail_OnlyBuyerCanCall() public {}
    function test_releaseFunds_fail_NotInAReleasableState() public {}
    function test_event_releaseFunds_FundsReleased() public {}

    // TEST raiseDispute(uint256 escrowId) onlyParticipant
    function test_raiseDispute_success() public {}
    function test_raiseDispute_fail_NotAuthorised() public {}
    function test_raiseDispute_fail_NotDisputable() public {}
    function test_event_raiseDispute_DisputeRaised() public {}

    // TEST resolveDispute(uint256 escrowId, bool releaseToSeller) onlyArbitrator
    function test_resolveDispute_success() public {}
    function test_resolveDispute_fail_OnlyArbitratorCanCall() public {}
    function test_resolveDispute_fail_NotInDispute() public {}
    function test_event_resolveDispute_DisputeResolved() public {}
}
