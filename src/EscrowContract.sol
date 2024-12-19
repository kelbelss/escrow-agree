// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

contract EscrowContract {
    // enum
    enum EscrowStatus {
        Pending,
        Completed,
        Disputed,
        Resolved
    }

    // struct
    struct Escrow {
        address payable buyer;
        address payable seller;
        address arbitrator;
        uint256 amount;
        EscrowStatus status;
    }

    // variables and mappings
    uint256 public escrowCount;
    mapping(uint256 id => Escrow) public escrows;

    // events
    event EscrowCreated(uint256 escrowId, address buyer, address seller, uint256 amount);

    // modifiers - onlyBuyer, onlyParticipant, onlyArbitrator
    modifier onlyBuyer(uint256 escrowId) {
        require(msg.sender == escrows[escrowId].buyer, "Only buyer can call this function");
        _;
    }

    // functions

    // createEscrow

    function createEscrow(address payable seller, address arbitrator) external payable {
        require(msg.value > 0, "Amount being escrowed must be larger than 0");

        uint256 escrowId = escrowCount++;
        escrows[escrowId] = Escrow({
            buyer: payable(msg.sender),
            seller: seller,
            arbitrator: arbitrator,
            amount: msg.value,
            status: EscrowStatus.Pending
        });

        emit EscrowCreated(escrowId, msg.sender, seller, msg.value);
    }

    // function releaseFunds

    function releaseFunds(uint256 escrowId) external onlyBuyer(escrowId) {
        Escrow storage escrow = escrows[escrowId];
    }

    // function raiseDispute

    // function resolveDispute
}
