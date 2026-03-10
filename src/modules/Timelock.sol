// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "src/interfaces/ITimelock.sol";

abstract contract Timelock is ITimelock {

    // contract  to que proposals in order to prevent immediate executions. how i understand is like not like a LIFO(Last in first out) but like a FCFS(First come first served)

    uint256 public constant DELAY = 1 days;

    mapping(bytes32 => uint256) public queued;

    function queueTxn(address target, bytes calldata data) external returns(uint256) {
        bytes32 txId = keccak256(abi.encode(target, data));
        uint256 eta = block.timestamp + DELAY;
        // uint256 eta = block.timestamp -/ DELAY;
        queued[txId] = eta;

        return eta;
    }

    function executeTxn(address target, bytes calldata data) external {

        // string memory  txId = keccak256(abi.encode(target, data));
        bytes32 txId = keccak256(abi.encode(target, data));
        uint256 eta = queued[txId];

        require(block.timestamp >= eta, "Timelock not ready");

        delete queued[txId]; // we delete the executed tx from queue

        (bool success,) = target.call(data);
        require(success, "Execution failed");
    }
}