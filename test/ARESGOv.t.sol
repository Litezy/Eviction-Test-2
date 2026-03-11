// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "src/core/ARESGovernance.sol";
import "src/modules/Timelock.sol";
import "src/libraries/SigLib.sol";

contract GovernanceTest is Test {
    ARESGovernance gov;
    Timelock timelock;

    address[] governors;
    bytes32 merkleRoot;

    uint256 governorKey = 0xA11CE;
    address governorAddr;

    address user1 = address(0x1);
    address nonGovernor = address(0xdead);

    function setUp() public {
        timelock = new Timelock();
        governorAddr = vm.addr(governorKey);

        governors.push(governorAddr);

        merkleRoot = keccak256(abi.encode(user1));

        gov = new ARESGovernance(address(timelock), governors, merkleRoot);
    }

    function _propose() internal returns (uint256) {
        vm.prank(governorAddr);
        return gov.createProposal(address(0x123), hex"1234");
    }

    function _approveAndQueue(uint256 pid) internal {
        vm.prank(governorAddr);
        gov.approve(pid);
        gov.queue(pid);
    }

    function _sigDigest(uint256 pid) internal view returns (bytes32) {
        bytes32 domainSep = SigLib.domainSeparator(address(gov));
        bytes32 structHash = SigLib.hashApproval(
            pid,
            governorAddr,
            gov.nonces(governorAddr)
        );
        return keccak256(abi.encodePacked("\x19\x01", domainSep, structHash));
    }

    function testCreateApproveQueueExecute() public {
        uint256 pid = _propose();
        assertEq(pid, 1);

        vm.prank(governorAddr);
        gov.approve(pid);
        assertEq(gov.rewards(governorAddr), 1 ether);

        gov.queue(pid);
        (, , , , , uint256 eta) = gov.getProposal(pid);
        assertTrue(eta > 0);

        vm.warp(block.timestamp + 1 days + 1);
        gov.execute(pid);
        (, , , , bool executed, ) = gov.getProposal(pid);
        assertTrue(executed);
    }

    function testCannotDoubleApprove() public {
        uint256 pid = _propose();
        vm.prank(governorAddr);
        gov.approve(pid);
        vm.prank(governorAddr);
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
        gov.checkEligibility(proof);
        vm.prank(user1);
        vm.expectRevert("already claimed");
        gov.checkEligibility(proof);
    }

    function testCannotClaimInvalidProof() public {
        bytes32[] memory badProof = new bytes32[](1);
        badProof[0] = keccak256(abi.encode(nonGovernor));
        vm.prank(nonGovernor);
        vm.expectRevert("invalid proof");
        gov.checkEligibility(badProof);
    }

    function testPrematureExecution() public {
        uint256 pid = _propose();
        _approveAndQueue(pid);
        vm.expectRevert("Timelock not ready");
        gov.execute(pid);
    }

    function testCannotReplaySignature() public {
        uint256 pid = _propose();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(governorKey, _sigDigest(pid));

        gov.approveBySig(pid, governorAddr, v, r, s);

        vm.expectRevert("sig mismatch");
        gov.approveBySig(pid, governorAddr, v, r, s);
    }

    function testCannotCancelByNonGovernor() public {
        uint256 pid = _propose();
        vm.prank(nonGovernor);
        vm.expectRevert("not governor");
        gov.cancelProposal(pid);
    }
}
