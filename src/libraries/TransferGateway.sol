// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

 library transferGate {
    
    function transferGateway(address to, uint amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "transfer failed");
    }
}