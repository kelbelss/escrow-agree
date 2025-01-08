## Escrow Agree 

**Decentralized Escrow Service**

### Basic V1:

-   **Escrow Creation**: Buyer locks funds into escrow contract and specifies a seller and arbitrator (will be kept as a simple address for now).
-   **Comfirmation**: Buyer releases funds to the seller if the transaction is successful.
-   **Dispute**: Either party can flag a dispute.
-   **Mock Arbitration**: Arbitrator address resolves dispute by calling a function (release funds to buyer or seller). Will use random outcome to simulate decision for V1.

### How it works 📄

1. **Escrow Creation** - buyer creates an escrow by calling `createEscrow` with seller's address, arbitrator's address, and amount in msg.value.
2. **Releasing Funds** - buyer can call `releaseFunds` to transfer funds to the seller if no disputes are flagged.
3. **Raising a Dispute** - either party can call `raiseDispute` which will pause the transaction and move to a dispute state.
4. **Mock Arbitration** - arbitrator resolves disputes by calling `resolveDispute`. A `releaseToSeller` bool will determine who gets the funds.

### Test Coverage 📊

| File                   | % Lines         | % Statements    | % Branches      | % Funcs       |
|------------------------|-----------------|-----------------|-----------------|---------------|
| src/EscrowContract.sol | 🟩 100.00% (34/34) | 🟩 100.00% (37/37) | 🟩 100.00% (16/16) | 🟩 100.00% (8/8) |
| Total                  | 🟩 100.00% (34/34) | 🟩 100.00% (37/37) | 🟩 100.00% (16/16) | 🟩 100.00% (8/8) |

### V2 Ideas 🛠️

-   **Timeout Mechanism**: Automatically refund the funds if the buyer doesn't act in a set amount of time.
-   **Oracles**: Verify external conditions (courier API?).
-   **Off-chain Agreements for Legal Enforceability**: hashed documents stored on IPFS.
-   **Actual Arbitration**: Implement Kleros - a blockchain dispute resolution layer.
-   **Decentralised Identity System**: Verify users to increase credibility.
-   **Multi-Sig Escrow**: Hold funds in a milti-sig wallet requiring two of three parties to approve fund release.
-   **Fees/Monetisation**: Charge a percentage of escrowed amount or offer tiered services for premium arbitration options.




