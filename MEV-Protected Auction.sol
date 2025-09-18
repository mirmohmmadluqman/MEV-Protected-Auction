// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MEV-Protected Auction
 * @notice A sealed-bid auction to demonstrate MEV protection by hiding bids until the reveal phase.
 * @dev This is a simplified educational contract for research/demo purposes.
 */
contract MevProtectedAuction {
    struct Bid {
        bytes32 blindedBid; // Keccak256 hash of (value, secret)
        uint deposit;       // Ether locked as deposit
        bool revealed;      // Ensure reveal happens only once
    }

    address public beneficiary;
    uint public biddingEnd;
    uint public revealEnd;
    bool public ended;

    mapping(address => Bid) public bids;
    address public highestBidder;
    uint public highestBid;

    /// Events
    event AuctionEnded(address winner, uint amount);

    /// Modifiers
    modifier onlyBefore(uint _time) {
        require(block.timestamp < _time, "Too late");
        _;
    }

    modifier onlyAfter(uint _time) {
        require(block.timestamp > _time, "Too early");
        _;
    }

    constructor(uint _biddingTime, uint _revealTime, address _beneficiary) {
        beneficiary = _beneficiary;
        biddingEnd = block.timestamp + _biddingTime;
        revealEnd = biddingEnd + _revealTime;
    }

    /**
     * @notice Place a blinded bid (commitment phase)
     * @param _blindedBid keccak256(value, secret)
     */
    function bid(bytes32 _blindedBid)
        external
        payable
        onlyBefore(biddingEnd)
    {
        bids[msg.sender] = Bid({
            blindedBid: _blindedBid,
            deposit: msg.value,
            revealed: false
        });
    }

    /**
     * @notice Reveal the actual bid (reveal phase)
     * @param _value The bid value in wei
     * @param _secret The secret used in hash
     */
    function reveal(uint _value, string calldata _secret)
        external
        onlyAfter(biddingEnd)
        onlyBefore(revealEnd)
    {
        Bid storage bidToCheck = bids[msg.sender];
        require(!bidToCheck.revealed, "Already revealed");
        bidToCheck.revealed = true;

        bytes32 calcHash = keccak256(abi.encodePacked(_value, _secret));
        if (bidToCheck.blindedBid != calcHash) {
            // Invalid reveal -> no refund
            return;
        }

        if (bidToCheck.deposit >= _value) {
            if (_value > highestBid) {
                // Refund previous highest bidder
                payable(highestBidder).transfer(highestBid);
                highestBid = _value;
                highestBidder = msg.sender;
            }
        }
    }

    /**
     * @notice End the auction and send funds to beneficiary
     */
    function auctionEnd()
        external
        onlyAfter(revealEnd)
    {
        require(!ended, "Auction already ended");
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        payable(beneficiary).transfer(highestBid);
    }
}

/**
 * -------------------------
 * Example usage (in Foundry tests):
 *
 * // Commit phase:
 * bytes32 hash = keccak256(abi.encodePacked(bidValue, secret));
 * auction.bid{value: bidValue}(hash);
 *
 * // Reveal phase:
 * auction.reveal(bidValue, secret);
 */
