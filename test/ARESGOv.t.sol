// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "src/core/ARESGovernance.sol";
import "src/modules/Timelock.sol";

contract GovernanceTest is Test {
    ARESGovernance   gov;
    Timelock timelock;

    address[] governors;
    bytes32   merkleRoot;

    address user1       = address(0x1);
    address user2       = address(0x2);
    address nonGovernor = address(0xdead);

    function setUp() public {
        timelock = new Timelock();

        governors.push(address(this));

        merkleRoot = keccak256(abi.encode(user1));

        gov = new ARESGovernance(address(timelock), governors, merkleRoot);
    }

    function _propose() internal returns (uint256) {
        return gov.createProposal(address(0x123), hex"1234");
    }

    function _approveAndQueue(uint256 pid) internal {
        gov.approve(pid);
        gov.queue(pid);
    }

    function testCreateApproveQueueExecute() public {
        uint256 pid = _propose();
        assertEq(pid, 1);

        gov.approve(pid);
        assertEq(gov.rewards(address(this)), 1 ether);

        gov.queue(pid);
        (,,,, , uint256 eta) = gov.getProposal(pid);
        assertTrue(eta > 0);

        vm.warp(block.timestamp + 1 days + 1);
        gov.execute(pid);
        (,,,, bool executed,) = gov.getProposal(pid);
        assertTrue(executed);
    }

    function testClaimReward() public {
        bytes32[] memory proof = new bytes32[](0);

        vm.prank(user1);
        gov.claimReward(proof);

        assertEq(gov.rewards(user1), 1 ether);
    }

    function testCannotDoubleApprove() public {
        uint256 pid = _propose();
        gov.approve(pid);
        vm.expectRevert("Already approved");
        gov.approve(pid);
    }

    function testCannotCreateProposalByNonGovernor() public {
        vm.prank(nonGovernor);
        vm.expectRevert("not governor");
        gov.createProposal(address(0x123), hex"1234");
    }

    function testCannotQueueWithoutApproval() public {
        uint256 pid = _propose();
        vm.expectRevert("Not enough approvals");
        gov.queue(pid);
    }

    function testCannotExecuteTwice() public {
        uint256 pid = _propose();
        _approveAndQueue(pid);

        vm.warp(block.timestamp + 1 days + 1);
        gov.execute(pid);

        vm.expectRevert("Already executed");
        gov.execute(pid);
    }

    function testCannotClaimTwice() public {
        bytes32[] memory proof = new bytes32[](0);

        vm.prank(user1);
        gov.claimReward(proof);

        vm.prank(user1);
        vm.expectRevert("already claimed");
        gov.claimReward(proof);
    }

    function testCannotClaimInvalidProof() public {
        bytes32[] memory badProof = new bytes32[](1);
        badProof[0] = keccak256(abi.encode(nonGovernor));

        vm.prank(nonGovernor);
        vm.expectRevert("invalid proof");
        gov.claimReward(badProof);
    }

    function testProposalReplay() public {
        uint256 pid = _propose();
        _approveAndQueue(pid);

        vm.warp(block.timestamp + 1 days + 1);
        gov.execute(pid);

        vm.expectRevert("Already executed");
        gov.execute(pid);
    }

    function testPrematureExecution() public {
        uint256 pid = _propose();
        _approveAndQueue(pid);

        vm.expectRevert("Timelock not ready");
        gov.execute(pid);
    }
}