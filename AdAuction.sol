// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract AdAuction is Ownable, ReentrancyGuard {
    struct Auction {
        address publisher;
        uint256 nftId;
        uint256 commitDeadline;
        uint256 revealDeadline;
        bool settled;
        address winner;
        uint256 secondHighestBid;
    }

    struct Bid {
        bytes32 commitment;
        uint256 revealedAmount;
        bool revealed;
    }

    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => mapping(address => Bid)) public bids;
    mapping(uint256 => address[]) public bidders;

    constructor() Ownable(msg.sender) {}

    function createAuction(uint256 _auctionId, uint256 _nftId, uint256 _commitDuration, uint256 _revealDuration) external {
        auctions[_auctionId] = Auction({
            publisher: msg.sender,
            nftId: _nftId,
            commitDeadline: block.timestamp + _commitDuration,
            revealDeadline: block.timestamp + _commitDuration + _revealDuration,
            settled: false,
            winner: address(0),
            secondHighestBid: 0
        });
    }

    function commitBid(uint256 _auctionId, bytes32 _commitment) external {
        require(block.timestamp < auctions[_auctionId].commitDeadline, "Commit phase ended");
        bids[_auctionId][msg.sender].commitment = _commitment;
        bidders[_auctionId].push(msg.sender);
    }

    function revealBid(uint256 _auctionId, uint256 _amount, string calldata _salt) external payable {
        require(block.timestamp >= auctions[_auctionId].commitDeadline, "Commit phase active");
        require(block.timestamp < auctions[_auctionId].revealDeadline, "Reveal phase ended");
        require(msg.value == _amount, "Must send bid amount to escrow");

        bytes32 commitment = keccak256(abi.encodePacked(_amount, _salt));
        require(commitment == bids[_auctionId][msg.sender].commitment, "Invalid reveal");

        bids[_auctionId][msg.sender].revealedAmount = _amount;
        bids[_auctionId][msg.sender].revealed = true;
    }

    function settle(uint256 _auctionId) external nonReentrant {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp >= auction.revealDeadline, "Reveal phase active");
        require(!auction.settled, "Already settled");

        address highestBidder;
        uint256 highestBid = 0;
        uint256 secondHighest = 0;

        for (uint256 i = 0; i < bidders[_auctionId].length; i++) {
            address bidder = bidders[_auctionId][i];
            uint256 amount = bids[_auctionId][bidder].revealedAmount;

            if (amount > highestBid) {
                secondHighest = highestBid;
                highestBid = amount;
                highestBidder = bidder;
            } else if (amount > secondHighest) {
                secondHighest = amount;
            }
        }

        auction.winner = highestBidder;
        auction.secondHighestBid = secondHighest;
        auction.settled = true;

        // Refund the winner the difference (Second Price logic)
        uint256 refund = highestBid - secondHighest;
        if (refund > 0) payable(highestBidder).transfer(refund);
        
        // Pay the publisher
        payable(auction.publisher).transfer(secondHighest);
    }
}
