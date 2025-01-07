// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

/**
 * @title Escrow Contract
 * @author Kelly Smulian
 * @notice This contract allows buyers to lock funds, and only release funds to the seller if the transaction is successful.
 */
contract EscrowContract {
    /*//////////////////////////////////////////////////////////////
                                ENUMS
    //////////////////////////////////////////////////////////////*/
    enum EscrowStatus {
        Pending,
        Completed,
        Disputed,
        Resolved
    }

    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Struct to store information about each Escrow created
     * @dev Used in the escrows mapping
     */
    struct Escrow {
        address payable buyer;
        address payable seller;
        address arbitrator;
        uint256 amount;
        EscrowStatus status;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 public escrowCount;
    mapping(uint256 id => Escrow) public escrows;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event EscrowCreated(uint256 escrowId, address indexed buyer, address indexed seller, uint256 amount);
    event FundsReleased(uint256 escrowId, address indexed seller);
    event DisputeRaised(uint256 escrowId);
    event DisputeResolved(uint256 escrowId, address indexed recipient);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error EscrowContract__OnlyBuyerCanCall();
    error EscrowContract__NotAuthorised();
    error EscrowContract__OnlyArbitratorCanCall();
    error EscrowContract__InsufficientAmount();
    error EscrowContract__NotInAReleasableState();
    error EscrowContract__NotDisputable();
    error EscrowContract__NotInDispute();

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/
    // modifiers - onlyBuyer, onlyParticipant, onlyArbitrator
    modifier onlyBuyer(uint256 escrowId) {
        if (msg.sender != escrows[escrowId].buyer) {
            revert EscrowContract__OnlyBuyerCanCall();
        }

        _;
    }

    modifier onlyParticipant(uint256 escrowId) {
        Escrow memory escrow = escrows[escrowId];
        // require(
        //     msg.sender == escrow.buyer || msg.sender == escrow.seller || msg.sender == escrow.arbitrator,
        //     "Not authorized"
        // );
        if (msg.sender != escrow.buyer && msg.sender != escrow.seller && msg.sender != escrow.arbitrator) {
            revert EscrowContract__NotAuthorised();
        }
        _;
    }

    modifier onlyArbitrator(uint256 escrowId) {
        // require(msg.sender == escrows[escrowId].arbitrator, "Only arbitrator can call this function");

        if (msg.sender != escrows[escrowId].arbitrator) {
            revert EscrowContract__OnlyArbitratorCanCall();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    // v2 arbitrator address
    constructor() {}

    /*//////////////////////////////////////////////////////////////
                              MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function createEscrow(address payable seller, address arbitrator) external payable returns (uint256) {
        // require(msg.value > 0, "Amount being escrowed must be larger than 0");
        if (msg.value <= 0) {
            revert EscrowContract__InsufficientAmount();
        }
        escrowCount++;
        uint256 escrowId = escrowCount;
        escrows[escrowId] = Escrow({
            buyer: payable(msg.sender),
            seller: seller,
            arbitrator: arbitrator,
            amount: msg.value,
            status: EscrowStatus.Pending
        });

        emit EscrowCreated(escrowId, msg.sender, seller, msg.value);
        return escrowId;
    }

    function releaseFunds(uint256 escrowId) external onlyBuyer(escrowId) {
        Escrow storage escrow = escrows[escrowId];
        // require(escrow.status == EscrowStatus.Pending, "Escrow not in a releasable state");

        if (escrow.status != EscrowStatus.Pending) {
            revert EscrowContract__NotInAReleasableState();
        }

        escrow.status = EscrowStatus.Completed;
        escrow.seller.transfer(escrow.amount);

        emit FundsReleased(escrowId, escrow.seller);
    }

    function raiseDispute(uint256 escrowId) external onlyParticipant(escrowId) {
        Escrow storage escrow = escrows[escrowId];
        // require(escrow.status == EscrowStatus.Pending, "Escrow not disputable");

        if (escrow.status != EscrowStatus.Pending) {
            revert EscrowContract__NotDisputable();
        }

        escrow.status = EscrowStatus.Disputed;

        emit DisputeRaised(escrowId);
    }

    function resolveDispute(uint256 escrowId, bool releaseToSeller) external onlyArbitrator(escrowId) {
        Escrow storage escrow = escrows[escrowId];
        // require(escrow.status == EscrowStatus.Disputed, "Escrow not in dispute");

        if (escrow.status != EscrowStatus.Disputed) {
            revert EscrowContract__NotInDispute();
        }

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
