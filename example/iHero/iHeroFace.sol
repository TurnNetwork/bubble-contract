// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Bubble} from "../../bubbleLib/bubble.sol";
import {Log} from "../../bubbleLib/log/log.sol";

// 这是一个简单的游戏，英雄可以创建分身，用户为英雄的分身点赞，就会增加英雄的人气。
contract iHeroFace {
    string internal _name;
    string internal _website;
    string internal _introduce;
    string internal _gameType;
    address internal _logicContact;
    address  internal _owner;

    uint64 public allPopular = 0;    // 总人气
    uint32 internal _imageId = 0;    // 分身Id计数器
    uint256 internal constant _stakingAmount = 10000000000000000000;
    address constant _bubble = 0x2000000000000000000000000000000000000002;

    mapping(uint32 => uint) internal imageLog;   // 记录分身所在bubble
    mapping(address => uint32) internal contributorLog;

    event GetBubble(uint bubbleId);
    event CreateGame(uint indexed boundId, uint indexed bubbleId, address indexed Creator);
    event Transmit(uint boundId, uint popular);
    event JoinGame(uint indexed boundId, address indexed player);
    event EndGame(uint indexed boundId);

    modifier onlyBubble() {
        // 需要多签算法检查合约支持，暂无法实现
        // require(msg.sender == _bubble, "sender must be bubble contract");
        _;
    }

    modifier onlyCreator() {
        require(msg.sender == _bubble, "sender must be bubble contract");
        _;
    }

    constructor(string memory name, string memory website, string memory introduce, string memory gameType, address logicContact) {
        _name = name;
        _website = website;
        _introduce = introduce;
        _gameType = gameType;
        _owner = msg.sender;
        _logicContact = logicContact;
    }

    function Name() public view returns(string memory) {
        return _name;
    }

    function Website() public view returns(string memory) {
        return _website;
    }

    function Introduce() public view returns(string memory) {
        return _introduce;
    }

    function GameType() public view returns(string memory) {
        return _gameType;
    }

    function GetBubbleId(uint32 imageId) external view returns(uint) {
        return imageLog[imageId];
    }

    function getContribution(address contributor) public view returns (uint) {
        return contributorLog[contributor];
    }

    // 获取bubbleId
    function getBubble(uint8 size) public {
        uint bubbleId = Bubble.selectBubble(size);
        emit GetBubble(bubbleId);
    }

    // 为英雄创建分身到bubble链
    function addImage(uint bubbleId) public {
        _imageId++;
        imageLog[_imageId] = bubbleId;
        Bubble.remoteDeploy(bubbleId, _logicContact, _stakingAmount, bytes(""));

        emit CreateGame(_imageId, bubbleId, msg.sender);
        emit JoinGame(_imageId, msg.sender);
    }

    // 获取从bubble链上传回的人气（只接收logic合约的远程调用）  // 原则：游戏逻辑不在主链进行，只在主链发送
    function transmit(uint32 imageId, uint32 popular) public onlyBubble {
        allPopular += popular;
        contributorLog[msg.sender] += popular;

        emit Transmit(imageId, popular);
    }

    // 手动销毁镜像（在bubble链上所有人气都被传回后再调用，否则会损失人气）
    function delImage(uint32 imageId) public {
        uint bubbleId = imageLog[imageId];
        Bubble.remoteRemove(bubbleId, _logicContact);

        imageLog[imageId] = 0;  // 清理镜像绑定的bubble信息
        emit EndGame(imageId);
    }

    // 在bubble被强制销毁时，销毁镜像并接收回传的人气（只接收logic合约的远程调用）
    function destroyExecutor(uint32 imageId, uint32 popular) public onlyBubble {
        transmit(imageId, popular);

        imageLog[imageId] = 0;  // 清理镜像绑定的bubble信息
        emit EndGame(imageId);
    }
}