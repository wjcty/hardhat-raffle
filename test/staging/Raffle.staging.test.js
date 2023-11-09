const { assert, expect } = require('chai')
const { network, deployments, ethers } = require('hardhat')
const {
    developmentChains,
    networkConfig
} = require('../../helper-hardhat-config')

developmentChains.includes(network.name)
    ? describe.skip
    : describe('Raffle Staging Tests', function () {
          let raffle, raffleContract, raffleEntranceFee, player // , deployer

          beforeEach(async () => {
              accounts = await ethers.getSigners()
              player = accounts[0]
              raffleContract = await ethers.getContract('Raffle')
              raffle = raffleContract.connect(player)
              raffleEntranceFee = await raffle.getEntranceFee()
          })

          describe('fulfillRandomWords', () => {
              it('works with live Chainlink keepers VRF randow number', async () => {
                  const startingTimeStamp = await raffle.getLastTimeStamp()
                  const accounts = await ethers.getSigners()
                  await new Promise(async (resolve, reject) => {
                      raffle.once('WinnerPicked', async () => {
                          console.log('WinnerPicked event fired!')
                          try {
                              const recentWinner =
                                  await raffle.getRecentWinner()
                              const raffleState = await raffle.getRaffleState()
                              const endingWinnerBalance =
                                  await accounts[0].getBalance()
                              const endingTimeStamp =
                                  await raffle.getLastTimeStamp()

                              // 数组应被清空
                              await expect(raffle.getPlayer(0)).to.be.reverted
                              assert.equal(
                                  recentWinner.toString(),
                                  accounts[0].address
                              )
                              assert.equal(raffleState, 0)
                              assert.equal(
                                  endingWinnerBalance.toString(),
                                  startingWinnerBalance.add(raffleEntranceFee)
                                      .toString
                              )
                              assert(endingTimeStamp > startingTimeStamp)
                              resolve()
                          } catch (e) {
                              reject(e)
                          }
                      })
                      const tx = await raffle.enterRaffle({
                          value: raffleEntranceFee
                      })
                      await tx.wait(1)
                      const startingWinnerBalance =
                          await accounts[0].getBalance()
                  })
              })
          })
      })
