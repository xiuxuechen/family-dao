// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {FamilyToken} from "../src/FamilyToken.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {Box} from "../src/Box.sol";

contract MyGovernorTest is Test {
    FamilyToken token;
    TimeLock timelock;
    MyGovernor governor;
    Box box;

    address[] proposers;
    address[] executors;

    bytes[] functionCalls;
    address[] addressesToCall;
    uint256[] values;

    address public constant VOTER = address(1);

    function setUp() public {
        token = new FamilyToken();
        token.mint(VOTER, 100 ether);

        vm.prank(VOTER);
        token.delegate(VOTER);

        timelock = new TimeLock(1 hours, proposers, executors);
        governor = new MyGovernor(token, timelock);

        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));
        //timelock.grantRole(timelock.CANCELLER_ROLE(), address(this));

        box = new Box();
        box.transferOwnership(address(timelock));
    }

    function testCantUpdateBoxWithoutGovernance() public {
        vm.expectRevert();
        box.store(1);
    }

    function testGovernanceUpdatesBox() public {
        uint256 valueToStore = 666;
        string memory description = "Store 666 in Box";
        bytes memory encodedFunctionCall = abi.encodeWithSignature(
            "store(uint256)",
            valueToStore
        );
        addressesToCall.push(address(box));
        values.push(0);
        functionCalls.push(encodedFunctionCall);
        uint256 proposalId = governor.propose(
            addressesToCall,
            values,
            functionCalls,
            description
        );
        console.log(unicode"提案状态:%s", uint256(governor.state(proposalId)));
        assertEq(uint256(governor.state(proposalId)), 0);

        vm.warp(block.timestamp + 1 days + 1);
        vm.roll(block.number + 1 days + 1);

        console.log(
            unicode"一天后提案状态:%s",
            uint256(governor.state(proposalId))
        );
        assertEq(uint256(governor.state(proposalId)), 1);

        string memory reason = "yeah yeah yeah I like it guys";
        //0反对 1赞成 2弃权
        uint8 voteWay = 1;
        vm.prank(VOTER);
        governor.castVoteWithReason(proposalId, voteWay, reason);

        vm.warp(block.timestamp + 1 weeks + 1);
        vm.roll(block.number + 1 weeks + 1);

        console.log(
            unicode"投票一周后提案状态:%s",
            uint256(governor.state(proposalId))
        );
        assertEq(uint256(governor.state(proposalId)), 4);

        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(addressesToCall, values, functionCalls, descriptionHash);

        vm.warp(block.timestamp + 1 hours + 1);
        vm.roll(block.number + 1 hours + 1);

        console.log(
            unicode"排队一小时后提案状态:%s",
            uint256(governor.state(proposalId))
        );
        assertEq(uint256(governor.state(proposalId)), 5);

        governor.execute(
            addressesToCall,
            values,
            functionCalls,
            descriptionHash
        );
        console.log(
            unicode"执行成功后提案状态:%s",
            uint256(governor.state(proposalId))
        );
        assertEq(uint256(governor.state(proposalId)), 7);
        assertEq(box.retrieve(), valueToStore);
    }
}
