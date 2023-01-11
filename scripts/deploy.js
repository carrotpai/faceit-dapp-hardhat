const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log(`Deploying contracts with account: ${deployer.address}`);
    const balance = await deployer.getBalance();
    console.log(`Account balance: ${balance.toString()}`)

    const AccountFactory = await ethers.getContractFactory("Account", deployer);
    const account = await AccountFactory.deploy();
    console.log(`Account-contract address: ${account.address}`)
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.log(error);
        process.exit(1);
    })