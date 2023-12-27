// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Bubble} from "../../bubbleLib/bubble.sol";


contract iHeroLogic {
    address constant _bubble = 0x2000000000000000000000000000000000000002;
    address constant public creator = 0x36c756417E63F740d83908d5216310A4603d6ecc;
    uint32 public imageId;
    uint32 public popular;

    event AddPopular(uint popularId);
    event SendPopular(uint count);
    event EndGame(uint256 blockNumber);

    modifier onlyBubble() {
        require(msg.sender == _bubble, "sender must be bubble contract");
        _;
    }

    modifier onlyCreator() {
        require(msg.sender == creator, "sender must be contract creator");
        _;
    }

    // 在bubble链上为英雄增加人气
    function addPopular() public {
        popular++;

        emit AddPopular(popular);
    }

    // 将bubble链累积的人气结算到主链
    function sendPopular() public {
        bytes memory callData = abi.encodeWithSignature("transmit(uint32 imageId, uint32 popular)", imageId, popular);
        Bubble.remoteCallBack(address(this), callData);

        emit SendPopular(popular);
        popular = 0;   // 清空人气
    }

    // bubble链被强制销毁时自动执行（将bubble链累积的人气结算到主链）
    function destroy() public onlyBubble {
        bytes memory callData = abi.encodeWithSignature("destroyExecutor(uint32 imageId, uint32 popular)", imageId, popular);
        Bubble.remoteCallBack(address(this), callData);
        
        emit EndGame(block.number);
        popular = 0;   // 清空人气
    }
}