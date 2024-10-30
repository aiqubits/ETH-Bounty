// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Auction {
    // 拍卖人
    address payable public owner;
    // 拍卖结束时间
    uint public biddingEnd;
    // 拍卖价格
    uint public biddingPrice;
    // 最高出价人
    address public highestBidder;
    // 最高出价
    uint public highestBid;

    // 出价者地址 => 出价
    mapping(address => uint) public bids;

    // 临结束拍卖5分钟 加权竞拍者 new feat1
    address public addWeightBidder;

    // 出价者地址 => 最近一次出价时间 // new feat2
    mapping(address => uint) public lastBidTime;
    uint public cooldownPeriod = 5 minutes; // Cooldown period in seconds

    // 出价者地址 => 出价数量
    event Bid(address bidder, uint amount);
    // 出价者提取资金事件
    event Withdraw(address bidder, uint amount);
    // 拍卖结束事件
    event AuctionEnd(address winner, uint amount);

    constructor(uint _biddingEnd, uint _biddingPrice) {
        owner = payable(msg.sender);
        biddingEnd = block.timestamp + _biddingEnd;
        biddingPrice = _biddingPrice;
        addWeightBidder = address(0);
    }

    function bid() public payable {
        require(block.timestamp < biddingEnd, "Bidding has ended.");
        require(msg.value >= biddingPrice, "Bid amount is too low.");

        // Add 5 minutes cooldown period
        require(block.timestamp >= lastBidTime[msg.sender] + cooldownPeriod, "You must wait 5 minutes before bidding again.");
        lastBidTime[msg.sender] = block.timestamp;

        // Add bidding end time
        if (biddingEnd - block.timestamp < 5 minutes) {
            biddingEnd += (5 * 60); // Extend the auction by 5 minutes if a bid is placed in the last 5 minutes
        }

        bids[msg.sender] += msg.value;

        // Add price weight when 5 minutes left
        uint adjustedBid = msg.value;
        if (biddingEnd - block.timestamp <= (5 * 60) ) {
            adjustedBid = (msg.value * 12) / 10; // Adjust the bid by a factor of 1.5 in the last 5 minutes
            addWeightBidder = msg.sender;
        }

        if (adjustedBid > highestBid) {
            highestBidder = msg.sender;
            highestBid = adjustedBid;
        }
        
        emit Bid(msg.sender, msg.value);
    }

    function bidderWithdraw() public returns (bool) {
        require(block.timestamp > biddingEnd, "Bidding is still ongoing.");
        uint amount = bids[msg.sender];
        require(amount > 0, "You have not bid.");
        
        payable(msg.sender).transfer(amount);

        emit Withdraw(msg.sender, amount);
        
        return true;
    }

    function auctionEndWithdraw() public {
        require(block.timestamp > biddingEnd, "Bidding is still ongoing.");
        require(msg.sender == owner, "Only the owner can withdraw.");

        uint highestbidend = getHighestBid();
        require(highestbidend > 0, "Highestbid is zero, Can't withdraw.");

        uint amount = address(this).balance;
        if (amount >= highestbidend) {
            payable(msg.sender).transfer(highestbidend);
        } else {
            payable(msg.sender).transfer(amount);
        }



        emit AuctionEnd(highestBidder, highestBid);
    }

    function getHighestBidder() public view returns (address) {
        return highestBidder;
    }

    function getHighestBid() public view returns (uint) {
        if (addWeightBidder != address(0)) {
            return (highestBid * 10) / 12 ;
        }

        return highestBid;
    }
}