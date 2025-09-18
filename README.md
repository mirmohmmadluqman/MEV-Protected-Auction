# MEV-Protected Auction


A Solidity smart contract that demonstrates **commit–reveal sealed-bid auctions** to reduce **MEV (Maximal Extractable Value)** risks such as front-running. This is a simplified educational example suitable for research, learning, and portfolio projects.


---


## Features
- **Commit Phase:** Users submit a blinded bid (hash of bid value + secret).
- **Reveal Phase:** Users reveal their actual bid and secret, which must match their commitment.
- **Winner Selection:** Highest valid revealed bid wins the auction.
- **Refunds:** Previous highest bidder automatically gets refunded.
- **Beneficiary Payout:** Auction funds are transferred to the beneficiary at the end.
