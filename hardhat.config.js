require('@nomiclabs/hardhat-waffle')
require('@nomiclabs/hardhat-etherscan')
require('hardhat-deploy')
require('solidity-coverage')
require('hardhat-gas-reporter')
require('hardhat-contract-sizer')
require('dotenv').config()

// 本地部署失败时加
const { ProxyAgent, setGlobalDispatcher } = require('undici')
// 这里的地址是默认的主机IP地址
const proxyAgent = new ProxyAgent('http://192.168.1.101:7890')
setGlobalDispatcher(proxyAgent)

const GOERLI_RPC_URL = process.env.GOERLI_RPC_URL || ''
const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL || ''
const PRIVATE_KEY = process.env.PRIVATE_KEY || ''
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || ''
const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY || ''

module.exports = {
    defaultNetwork: 'hardhat',
    networks: {
        hardhat: {
            chainId: 31337,
            blockConfirmations: 1
        },
        localhost: {
            chainId: 31337,
            blockConfirmations: 1
        },
        sepolia: {
            url: SEPOLIA_RPC_URL,
            chainId: 11155111,
            accounts: [PRIVATE_KEY],
            blockConfirmations: 6
        },
        goerli: {
            url: GOERLI_RPC_URL,
            chainId: 5,
            accounts: [PRIVATE_KEY],
            blockConfirmations: 6
        }
    },
    etherscan: {
        // yarn hardhat verify --network <NETWORK> <CONTRACT_ADDRESS> <CONSTRUCTOR_PARAMETERS>
        apiKey: {
            sepolia: ETHERSCAN_API_KEY
        },
        // In case the module can't find the rinkeby etherscan automatically
        customChains: [
            {
                network: 'sepolia',
                chainId: 11155111,
                urls: {
                    apiURL: 'http://api-sepolia.etherscan.io/api',
                    browserURL: 'https://sepolia.etherscan.io'
                }
            }
        ]
    },
    gasReporter: {
        enabled: false,
        currency: 'USD',
        outputFile: 'gas-report.txt',
        noColors: true
        // coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    },
    namedAccounts: {
        deployer: {
            default: 0
        },
        player: {
            default: 1
        }
    },
    solidity: {
        compilers: [
            {
                version: '0.8.8'
            },
            {
                version: '0.4.24'
            }
        ]
    },
    mocha: {
        timeout: 500000 // ms
    }
}
