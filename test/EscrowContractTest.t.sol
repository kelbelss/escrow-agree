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

    address BUYER = makeAddr("buyer");
    address SELLER = makeAddr("seller");
    address ARBITRATOR = makeAddr("arbitrator");

    function setUp() public {
        vm.prank(BUYER);
        escrowContract = EscrowContract();

        // give buyer funds - 10 ETH
        deal(BUYER, 10e18);
    }

    function test_buyer_funds() public {
        assertEq(escrowContract.balanceOf(BUYER), 10e18);
    }

    // fail/error, success, event - consider checking enum status changes

    // TEST CreateEscrow(address payable seller, address arbitrator)
    function test_createEscrow_success() public {} // check struct
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
