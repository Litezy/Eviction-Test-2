// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {transferGate} from "src/libraries/TransferGateway.sol";

contract Treasury {
    //treasury contract to ascertain that governance  is making a transfer call
    address public governance;

    constructor(address _gov) {
        require(_gov != address(0), "invalid address");
        governance = _gov;
    }

    event Transfer(address to, uint value);

    modifier onlyGovernance() {
        require(msg.sender == governance, "Not governance");
        _;
    }

    function transfer(address to, uint256 amount) public onlyGovernance {
        require(to != address(0), "invalid address");
        require(amount > 0, "invalid amount");
        transferGate.transferGateway(to, amount);
        emit Transfer(to, amount);
    }

    receive() external payable {}
}
