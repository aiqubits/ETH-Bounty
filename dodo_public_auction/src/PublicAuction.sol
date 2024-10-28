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
    }

    function bid() public payable {
        require(block.timestamp < biddingEnd, "Bidding has ended.");
        require(msg.value >= biddingPrice, "Bid amount is too low.");
        require(bids[msg.sender] == 0, "You have already bid.");
        bids[msg.sender] = msg.value;
        if (msg.value > highestBid) {
            highestBidder = msg.sender;
            highestBid = msg.value;
        }

        emit Bid(msg.sender, msg.value);
    }

    function withdraw() public returns (bool) {
        require(block.timestamp > biddingEnd, "Bidding is still ongoing.");
        uint amount = bids[msg.sender];
        require(amount > 0, "You have not bid.");
        
        payable(msg.sender).transfer(amount);
        bids[msg.sender] = 0;

        emit Withdraw(msg.sender, amount);
        
        return true;
    }

    function auctionEnd() public {
        require(block.timestamp > biddingEnd, "Bidding is still ongoing.");
        require(msg.sender == owner, "Only the owner can withdraw.");
        uint amount = address(this).balance;
        require(amount > 0, "Amount is zero.");

        payable(msg.sender).transfer(amount);

        emit AuctionEnd(highestBidder, highestBid);
    }

    function getHighestBidder() public view returns (address) {
        return highestBidder;
    }

    function getHighestBid() public view returns (uint) {
        return highestBid;
    }
}