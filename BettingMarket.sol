// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract BettingMarketFactory {
    address payable[] public deployedMarkets;

    function createMarket(string memory title, string memory description) public {
        address newMarket = address(new BettingMarket(title, description, msg.sender));
        deployedMarkets.push(payable(newMarket));
    }

    function getMarkets() public view returns (address payable[] memory) {
        return deployedMarkets;
    }
}

contract BettingMarket {


    struct Market {
        string title;
        string description;
        bool complete;
        uint bettorCount;
    }

    address public manager;
    Market public market;
    uint public minimumContribution = 100;
    mapping (address => uint) public yesBettors;
    mapping (address => uint) public noBettors;
    address payable[] public yesNames;
    address payable[] public noNames;
    uint yesTotal;
    uint noTotal;
    bool locked = false;


    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    constructor (string memory title, string memory description, address creator) {
        manager = creator;
        market.title = title;
        market.description = description;
        market.complete = false;
        market.bettorCount = 0;
    }

    function makeYesBet() public payable{
        require(!locked && !market.complete);
        require(msg.value > minimumContribution);
        yesBettors[msg.sender] = msg.value;
        yesNames.push(payable(msg.sender));
        yesTotal += msg.value;
        market.bettorCount++;
    }

    function makeNoBet() public payable{
        require(!locked && !market.complete);
        require(msg.value > minimumContribution);
        noBettors[msg.sender] = msg.value;
        noNames.push(payable(msg.sender));
        noTotal += msg.value;
        market.bettorCount++;
    }

    function lock() public restricted {
        locked = true;
    }
    
    function finalizeMarket(bool complete) public restricted {
        require(!market.complete);
        uint currentBalance = address(this).balance;
        require(currentBalance > 0);
        uint winValue;
        if (complete) {
            for (uint i=0; i<yesNames.length; i++) {
                winValue = (yesBettors[ yesNames[i] ] * currentBalance) / yesTotal;
                yesNames[i].transfer(winValue);
            }
        } else {
            for (uint i=0; i<noNames.length; i++) {
                winValue = (noBettors[ noNames[i] ] * currentBalance) / noTotal;
                noNames[i].transfer(winValue);
            }
        }
        market.complete = true;
    }

    function refundBets() public restricted {
        require(!market.complete);
        for (uint i=0; i<yesNames.length; i++) {
            yesNames[i].transfer(yesBettors[yesNames[i]]);
        }
        for (uint i=0; i<noNames.length; i++) {
            noNames[i].transfer(noBettors[noNames[i]]);
        }
        market.complete = true;
    }

    function getSummary() public view returns(string memory, string memory, bool, uint, 
    uint, uint, uint, uint, uint, address, bool) {
        return (
            market.title,
            market.description,
            market.complete,
            market.bettorCount,
            address(this).balance,
            yesNames.length,
            noNames.length,
            yesTotal,
            noTotal,
            manager,
            locked
        );
    }

}