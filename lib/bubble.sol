pragma solidity ^0.8.9;

import {RLPReader} from "./rlp/RLPReader.sol";
import {RLPWriter} from "./rlp/RLPWriter.sol";
import {Log} from "./log/log.sol";

library Bubble {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for RLPReader.Iterator;
    using RLPReader for bytes;

    function bytesToHex(bytes memory data) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 * data.length + 2);

        str[0] = "0";
        str[1] = "x";

        for (uint i = 0; i < data.length; i++) {
            str[2 * i + 2] = alphabet[uint(uint8(data[i] >> 4))];
            str[2 * i + 3] = alphabet[uint(uint8(data[i] & 0x0f))];
        }

        return string(str);
    }

    function bytesToBytes32(bytes memory data) public pure returns (bytes32) {
        require(data.length <= 32, "Input data must be at least 32 bytes");

        bytes32 result;
        // 截取前32个字节
        assembly {
            result := mload(add(data, 32))
        }

        return result;
    }

    function callPrecompile(bytes memory data,address addr) public returns(bytes memory)  {
        uint256 len = data.length;
        uint retsize;
        bytes memory resval;
        assembly {
            if iszero(call(gas(), addr, 0,  add(data, 0x20), len, 0, 0)) {
                invalid()
            }
            retsize := returndatasize()
        }
        resval = new bytes(retsize);
        assembly {
            returndatacopy(add(resval, 0x20), 0, returndatasize())
        }
        return resval;
    }

    function selectBubble(uint8 size) internal returns (uint) {
        bytes[] memory dataArrays = new bytes[](2);

        bytes memory fnData = RLPWriter.writeBytes(RLPWriter.writeUint(8001));
        bytes memory sizeData = RLPWriter.writeBytes(RLPWriter.writeUint(size));
        dataArrays[0] = fnData;
        dataArrays[1] = sizeData;
        bytes memory rlpData = RLPWriter.writeList(dataArrays);

        bytes memory returnData = callPrecompile(rlpData, address(0x2000000000000000000000000000000000000002));

        RLPReader.RLPItem[] memory items = returnData.toRlpItem().toList();
        bytes memory ByteId = items[0].toBytes();
        uint bubbleId = ByteId.toRlpItem().toUint();

        return bubbleId;
    }

    function remoteDeploy(uint bubbleID, address target, uint256 amount, bytes memory data) internal {
        bytes[] memory dataArrays = new bytes[](5);

        bytes memory fnData = RLPWriter.writeBytes(RLPWriter.writeUint(8006));
        bytes memory bubidData = RLPWriter.writeBytes(RLPWriter.writeUint(bubbleID));
        bytes memory targetData = RLPWriter.writeBytes(RLPWriter.writeAddress(target));
        bytes memory amountData = RLPWriter.writeBytes(RLPWriter.writeUint(amount));
        bytes memory dataData = RLPWriter.writeBytes(RLPWriter.writeBytes(data));

        dataArrays[0] = fnData;
        dataArrays[1] = bubidData;
        dataArrays[2] = targetData;
        dataArrays[3] = amountData;
        dataArrays[4] = dataData;
        bytes memory rlpData = RLPWriter.writeList(dataArrays);
        
        bytes memory success = callPrecompile(rlpData, address(0x2000000000000000000000000000000000000002));

        emit Log.LogMessage("remoteDeploy", 0, success);
    }

    function remoteCall(uint bubbleID, address target, bytes memory data) internal {
        bytes[] memory dataArrays = new bytes[](4);

        bytes memory fnData = RLPWriter.writeBytes(RLPWriter.writeUint(8007));
        bytes memory bubidData = RLPWriter.writeBytes(RLPWriter.writeUint(bubbleID));
        bytes memory targetData = RLPWriter.writeBytes(RLPWriter.writeAddress(target));
        bytes memory dataData = RLPWriter.writeBytes(RLPWriter.writeBytes(data));
        dataArrays[0] = fnData;
        dataArrays[1] = bubidData;
        dataArrays[2] = targetData;
        dataArrays[3] = dataData;
        bytes memory rlpData = RLPWriter.writeList(dataArrays);
        
        bytes memory success = callPrecompile(rlpData, address(0x2000000000000000000000000000000000000002));

        emit Log.LogMessage("remoteCall", 0, success);
    }

    function remoteCallBack(address target, bytes memory data) internal {
        bytes[] memory dataArrays = new bytes[](3);

        bytes memory fnData = RLPWriter.writeBytes(RLPWriter.writeUint(8003));
        bytes memory targetData = RLPWriter.writeBytes(RLPWriter.writeAddress(target));
        bytes memory dataData = RLPWriter.writeBytes(RLPWriter.writeBytes(data));
        dataArrays[0] = fnData;
        dataArrays[1] = targetData;
        dataArrays[2] = dataData;
        bytes memory rlpData = RLPWriter.writeList(dataArrays);
        
        bytes memory success = callPrecompile(rlpData, address(0x2000000000000000000000000000000000000001));

        emit Log.LogMessage("remoteCallBack", 0, success);
    }

    function remoteRemove(uint bubbleID, address target) internal {
        bytes[] memory dataArrays = new bytes[](3);

        bytes memory fnData = RLPWriter.writeBytes(RLPWriter.writeUint(8009));
        bytes memory bubidData = RLPWriter.writeBytes(RLPWriter.writeUint(bubbleID));
        bytes memory targetData = RLPWriter.writeBytes(RLPWriter.writeAddress(target));
        dataArrays[0] = fnData;
        dataArrays[1] = bubidData;
        dataArrays[2] = targetData;
        bytes memory rlpData = RLPWriter.writeList(dataArrays);
        
        bytes memory success = callPrecompile(rlpData, address(0x2000000000000000000000000000000000000002));

        emit Log.LogMessage("remoteRemove", 0, success);
    }

}