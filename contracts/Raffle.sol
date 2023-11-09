// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

/* Errors */
error Raffle__UpkeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 raffleState
);
error Raffle__TransferFailed();
error Raffle__SendMoreToEnterRaffle();
error Raffle__RaffleNotOpen();

/**
 * @title 一个简单的抽奖合约
 * @author monkey
 * @notice 创建一个不可篡改的去中心化智能合约
 * @dev 实现了Chainlink VRFV2 以及 Chainlink Keepers
 */
contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    enum RaffleState {
        OPEN,
        CALCULATING
    }
    // 只修改一次，所以作为immutable 变量 更节省gas
    /* State variables */
    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    // gasLane 告诉chainlink 所能接受的以wei为单位支付的gas价格上限
    bytes32 private immutable i_gasLane;
    /* 
        callbackGasLimit
        回调你合约的fulfillRandomWords请求时对应消耗的gas使用上限，
        超出该上限，则会锁定随机数fulfillRandomWords 的响应
    */
    uint32 private immutable i_callbackGasLimit;
    // chainlink节点在响应前该等待多少区块确认
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    // 获取的随机数数量
    uint32 private constant NUM_WORDS = 1;

    // Lottery Variables
    uint256 private immutable i_interval;
    uint256 private immutable i_entranceFee;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    address payable[] private s_players;
    RaffleState private s_raffleState;

    /* Events */
    event RequestedRaffleWinner(uint256 indexed requestId);
    event RaffleEnter(address indexed player);
    event WinnerPicked(address indexed player);

    /* Functions */
    //vrfCoordinatorV2 是负责随机数验证的合约的地址
    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint256 entranceFee,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        i_entranceFee = entranceFee;
        s_raffleState = RaffleState.OPEN; // RaffleState(0)
        s_lastTimeStamp = block.timestamp;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        // 之后向幸运儿支付ETH，此处将存储的地址都设置为payable的地址
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    /* 
        1 满足条件 checkUpkeep -> chainlink调用performUpkeep 
          即调用VRFCoordinatorV2Interface 的 requestRandomWords 获取随机数
        2 VRFConsumerBaseV2 的 fulfillRandomWords 验证随机数
     */
    /* 
    checkUpkeep 检查是否到时间去获取随机数，更新最新幸运儿 以及打钱
    什么时候返回true 以表示可以去获取随机数？
    1 彩票应处在 开放 状态
    2 满足设置的时间间隔
    3 彩票至少有1个玩家 一些ETH 
    4 订阅的 checkUpkeep 注入了LINK ?
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0"); // can we comment this out?
    }

    /* 
        checkUpkeep 返回为true时 chainlink节点会自动调用performUpkeep
     */
    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        /* 此处触发的事件多余，调用requestRandomWords 
           已经触发了类似事件包含requsetId 
        */
        emit RequestedRaffleWinner(requestId);
    }

    // 模函数 （求余
    function fulfillRandomWords(
        uint256 /* requestId */,
        // 包含随机数的数组 此处为1个随机数
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_players = new address payable[](0);
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        // 追踪记录以往的幸运儿
        emit WinnerPicked(recentWinner);
    }

    /** Getter Functions */

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }
}
