// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract Account {
    uint constant DURATION = 7 days;
    struct Player {
        string nickname;
        uint balance;
        uint rating;
        uint lastTimeClaimed;
        bool created;
    }

    address public faceitOwner;

    mapping(address => Player) private balances;

    constructor() {
        faceitOwner = msg.sender;
        console.log("Who is calling ctor: %s", msg.sender);
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
            created: true
        });

        balances[msg.sender] = newPlayer;
    }

    function getBalance() public view returns (uint) {
        return balances[msg.sender].balance;
    }

    function balanceAccrual(uint _rating) public {
        //require(block.timestamp - balances[msg.sender].lastTimeClaimed >= DURATION);
        balances[msg.sender].balance += 1;
        console.log(
            "account %s --- new Balance: %s with rating %s",
            msg.sender,
            balances[msg.sender].balance,
            _rating
        );
        address payable _to = payable(msg.sender);
    }

    function getETHforRating(uint _rating) private pure returns (uint) {
        return 1;
    }
}
