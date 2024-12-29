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
    event FundsReleased(uint256 escrowId, address recipient);
    event DisputeRaised(uint256 escrowId);
    event DisputeResolved(uint256 escrowId, address recipient);

    // modifiers - onlyBuyer, onlyParticipant, onlyArbitrator
    modifier onlyBuyer(uint256 escrowId) {
        require(msg.sender == escrows[escrowId].buyer, "Only buyer can call this function");
        _;
    }

    modifier onlyParticipant(uint256 escrowId) {
        Escrow memory escrow = escrows[escrowId];
        require(
            msg.sender == escrow.buyer || msg.sender == escrow.seller || msg.sender == escrow.arbitrator,
            "Not authorized"
        );
        _;
    }

    modifier onlyArbitrator(uint256 escrowId) {
        require(msg.sender == escrows[escrowId].arbitrator, "Only arbitrator can call this function");
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
        require(escrow.status == EscrowStatus.Pending, "Escrow not in a releasable state");

        escrow.status = EscrowStatus.Completed;
        escrow.seller.transfer(escrow.amount);

        emit FundsReleased(escrowId, escrow.seller);
    }

    // function raiseDispute

    function raiseDispute(uint256 escrowId) external onlyParticipant(escrowId) {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.status == EscrowStatus.Pending, "Escrow not disputable");

        escrow.status = EscrowStatus.Disputed;

        emit DisputeRaised(escrowId);
    }

    // function resolveDispute

    function resolveDispute(uint256 escrowId, bool releaseToSeller) external onlyArbitrator(escrowId) {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.status == EscrowStatus.Disputed, "Escrow not in dispute");

        escrow.status = EscrowStatus.Resolved;

        if (releaseToSeller) {
            escrow.seller.transfer(escrow.amount);
            emit DisputeResolved(escrowId, escrow.seller);
        } else {
            escrow.buyer.transfer(escrow.amount);
            emit DisputeResolved(escrowId, escrow.buyer);
        }
    }
}
