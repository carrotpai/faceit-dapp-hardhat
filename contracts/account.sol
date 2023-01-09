// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract Account {
    struct Player {
        address id;
        string nickname;
        uint balance;
    }

    uint public baseSupply = 0;
    uint public totalsupply = 1000000;

    mapping(address => Player) balances;

    constructor() {
        balances[msg.sender] = Player(msg.sender, "Tom", baseSupply);
    }

    function balanceOf(address account) external view returns (uint) {
        return balances[account].balance;
    }
}
