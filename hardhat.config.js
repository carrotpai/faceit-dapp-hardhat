/** @type import('hardhat/config').HardhatUserConfig */


require("@nomiclabs/hardhat-waffle");
require('solidity-coverage')


module.exports = {
    defaultNetwork: "hardhat",
    solidity: "0.8.17",
    networks: {
        hardhat: {
            chainId: 31337,
        },
        localhost: {
            url: "http://127.0.0.1:8545/",
            chainId: 31337,
        },
    }
};