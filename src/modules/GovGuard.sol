// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract GovGuard {

    mapping(address => bool) public governors;

    modifier onlyGovernor() {
        require(governors[msg.sender],"not governor");
        _;
    }

    function _setGovernors(address[] memory govs) internal {
        for(uint i; i < govs.length; i++){
            require(govs[i] != address(0),"Address 0 not allowed");
            governors[govs[i]] = true;
        }
    }
}