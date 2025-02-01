# SocialTippingPlatform-DevDock.ai
PS: Create a social tipping platform where anyone can tip for content creators. The EVM Smart contract should keep track of tokens for each content creators.

![image](https://github.com/user-attachments/assets/49ffbfeb-2485-49b7-a390-86a966e15d2d)


# Tipping DApp - Smart Contract & Frontend

A decentralized application (DApp) for tipping content creators on the blockchain. This repository includes a Solidity smart contract and a frontend interface.

---

## Key Features

### Smart Contract
1. **Creator Registration & Verification**:
   - Creators can register and be verified by moderators.
2. **Tipping**:
   - Users can send tips to creators with optional messages.
   - Batch tipping allows tipping multiple creators in one transaction.
3. **Withdrawals**:
   - Creators can withdraw tips after a cooldown period.
4. **Rate Limiting**:
   - Limits tips per user within 24 hours to prevent abuse.
5. **Upgradable Proxy**:
   - Uses a proxy pattern for upgradability without losing state.

### Frontend
1. **User-Friendly Interface**:
   - Easy tipping, creator registration, and withdrawals.
2. **Creator Profiles**:
   - Displays creator details and tip history.
3. **Wallet Integration**:
   - Seamless connection with MetaMask or other Ethereum wallets.

---

## Security Highlights

1. **Reentrancy Protection**:
   - Uses OpenZeppelin's `ReentrancyGuard` to prevent attacks.
2. **Role-Based Access Control**:
   - Admins and moderators have specific roles for managing the contract.
3. **Pausable**:
   - Admins can pause the contract in emergencies.
4. **Input Validation**:
   - Ensures all inputs are valid and safe.
5. **Proxy Security**:
   - Upgradability is controlled by a strict admin role.

---

## Setup

### Prerequisites
- Node.js (v16+)
- MetaMask or another Ethereum wallet.

### Steps
1. Clone the repo:
   ```bash
   git clone https://github.com/SOGeKING-NUL/SocialTippingPlatform-DevDock.ai
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Deploy the contract:
   contract already deployed with address: 0xE017F43975b2A1AC018AfBA4076A2b444EddAc8F 
   
4. Run the frontend:  run index.html   
---

## Deployment

To test: ```
index.html```

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

This DApp is designed to be secure, user-friendly, and efficient. For questions or feedback, feel free to reach out! 🚀
