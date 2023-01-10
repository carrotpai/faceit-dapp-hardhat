// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract Account {
    uint constant DURATION = 7 days;

    event Received(address, uint);

    receive() external payable {
        emit Received(msg.sender, msg.value);
        console.log("received: %s", address(this).balance);
    }

    struct Player {
        string nickname;
        uint balance;
        uint rating;
        uint lastTimeClaimed;
        bool created;
        bool participant;
    }

    address public faceitOwner;

    mapping(address => Player) private balances;

    constructor() {
        faceitOwner = msg.sender;
        console.log("Who is calling ctor: %s", msg.sender);
    }

    function participate() public payable {
        //require(balances[msg.sender].created)
        balances[msg.sender].participant = true;

        console.log("total sum on contract: %s", address(this).balance);
    }

    function createPlayerAccount(
        string calldata _nickname,
        uint _rating
    ) external {
        require(!balances[msg.sender].created);

        Player memory newPlayer = Player({
            nickname: _nickname,
            balance: 0,
            rating: _rating,
            lastTimeClaimed: block.timestamp,
            created: true,
            participant: false
        });

        balances[msg.sender] = newPlayer;
    }

    function getBalance() public view returns (uint) {
        return balances[msg.sender].balance;
    }

    function balanceAccrual(uint _rating) public {
        //require(block.timestamp - balances[msg.sender].lastTimeClaimed >= DURATION);
        //require(balances[msg.sender].created)
        //require(balances[msg.sender].participant)
        balances[msg.sender].balance += 1;
        console.log(
            "account %s --- new Balance: %s with rating %s",
            msg.sender,
            balances[msg.sender].balance,
            _rating
        );
        uint value = 1 wei;
        address payable _to = payable(msg.sender);
        require(address(this).balance > value);
        _to.transfer(value);
    }

    function getETHforRating(uint _rating) private view returns (uint) {
        return (balances[msg.sender].rating - _rating);
    }
}
