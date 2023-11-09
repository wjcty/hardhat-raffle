const { ethers } = require('hardhat')

const networkConfig = {
    11155111: {
        name: 'sepolia',
        vrfCoordinatorV2: '0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625',
        entranceFee: ethers.utils.parseEther('0.01'),
        gasLane:
            '0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c',
        subscriptionId: '6769',
        callbackGasLimit: '500000',
        keepersUpdateInterval: '30'
    },
    5: {
        name: 'goerli',
        vrfCoordinatorV2: '0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D',
        entranceFee: ethers.utils.parseEther('0.01'),
        gasLane:
            '0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15',
        subscriptionId: '0',
        callbackGasLimit: '500000',
        keepersUpdateInterval: '30'
    },
    31337: {
        name: 'hardhat',
        entranceFee: ethers.utils.parseEther('0.01'),
        gasLane:
            '0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc',
        callbackGasLimit: '500000',
        keepersUpdateInterval: '30'
    }
}

const developmentChains = ['hardhat', 'localhost']

module.exports = {
    networkConfig,
    developmentChains
}
