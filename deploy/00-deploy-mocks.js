const { network, ethers } = require('hardhat')

// goerli网 保底费用 每次请求花费 0.25LINK
const BASE_FEE = ethers.utils.parseEther('0.25')
// 0.000000001 LINK per gas
const GAS_PRICE_LINK = 1e9

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    const chainId = network.config.chainId

    if (chainId == 31337) {
        log('Local network detected! Deploying mocks...')
        await deploy('VRFCoordinatorV2Mock', {
            contract: 'VRFCoordinatorV2Mock',
            from: deployer,
            log: true,
            args: [BASE_FEE, GAS_PRICE_LINK]
        })
        log('Mocks Deployed!')
        log('----------------------------------------------------------')
    }
}

module.exports.tags = ['all', 'mocks']
