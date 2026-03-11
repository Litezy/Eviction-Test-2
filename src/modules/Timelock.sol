// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "src/interfaces/ITimelock.sol";

contract Timelock is ITimelock {
    uint256 public constant DELAY = 1 days;
    event Queued(bytes32 _txnID, uint _timeQueued);
    event Executed(address _target, uint _time);

    mapping(bytes32 => uint256) public queued;

    function queue(address target, bytes calldata data) external returns (uint256) {
        bytes32 txId = keccak256(abi.encode(target, data));
        uint256 eta = block.timestamp + DELAY;
        queued[txId] = eta;
        emit Queued(txId,block.timestamp);
        return eta;
    }

    function execute(address target, bytes calldata data) external {
        bytes32 txId = keccak256(abi.encode(target, data));
        uint256 eta = queued[txId];
        require(eta != 0, "not queued");
        require(block.timestamp >= eta, "Timelock not ready");
        delete queued[txId];
        (bool success,) = target.call(data);
        require(success, "Execution failed");
        emit Executed( target,block.timestamp);
    }
}