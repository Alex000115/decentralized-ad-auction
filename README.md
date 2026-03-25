# Decentralized Ad Auction

This repository provides a trustless framework for buying and selling digital advertising space. By moving the auction process on-chain, publishers can prove their reach and advertisers can verify that their bids are processed fairly.

## Features
* **NFT Ad Slots**: Each ad space (e.g., "Homepage Banner") is represented as a unique NFT.
* **Sealed-Bid (Commit/Reveal)**: Bidders submit a hash of their bid first, then reveal it later. This prevents competitors from seeing bids and outbidding by 1 wei.
* **Second-Price Logic**: The winner pays the price of the *second-highest* bid, incentivizing bidders to bid their true maximum value.

## Phases
1. **Commit**: Advertisers send `keccak256(bidAmount, salt)`.
2. **Reveal**: Advertisers send `bidAmount` and `salt`.
3. **Settle**: The contract identifies the winner and transfers the NFT/Permission.
