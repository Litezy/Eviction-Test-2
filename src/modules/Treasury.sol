// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Treasury {
    //treasury contract to ascertain that governance  is making a transfer call
    address public governance;

    constructor(address _gov) {
         require(_gov != address(0), "invalid address");
        governance = _gov;
    }

    event Transfer(address to, uint value);

    function transferGateway(address to, uint amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "transfer failed");
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "Not governance");
        _;
    }

    function transfer(address to, uint256 amount) external onlyGovernance {
        require(to != address(0), "invalid address");
        require(amount > 0, "invalid amount");

        transferGateway(to, amount);
        emit Transfer(to, amount);
    }

    receive() external payable {}
}
