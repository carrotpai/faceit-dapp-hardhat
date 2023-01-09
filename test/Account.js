const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('Account contract', () => {
    let Account, _Account, owner, addr1, addr2;

    beforeEach(async() => {
        Account = await ethers.getContractFactory("Account");
        _Account = await Account.deploy();
        [owner, addr1, addr2, _] = await ethers.getSigners();
    });
})