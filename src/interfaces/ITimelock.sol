// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITimelock {

    function queue(address target, bytes calldata data) external returns(uint256);

    function execute(address target, bytes calldata data) external;
    
}