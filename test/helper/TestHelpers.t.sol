// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "./GasReport.t.sol";

abstract contract TestHelpers is Test, GasReport {
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public zeroAddress = address(0);
    address public owner = makeAddr("owner");
    address public notOwner = makeAddr("notOwner");
    address public operator = makeAddr("operator");
    address public user1 = vm.addr(1);
    address public user2 = vm.addr(2);
    address public user3 = vm.addr(3);
    address public anotherContractAddress = makeAddr("anotherContract");

    constructor() {}

    modifier onlyOwner() {
        vm.startPrank(owner);
        vm.deal(owner, 100 ether);
        _;
        vm.stopPrank();
    }

    modifier onlyOperator() {
        vm.startPrank(operator);
        vm.deal(operator, 100 ether);
        _;
        vm.stopPrank();
    }

    modifier nonOwner() {
        vm.startPrank(notOwner);
        vm.deal(user1, 100 ether);
        _;
        vm.stopPrank();
    }

    modifier User(address user) {
        vm.startPrank(user, user);
        vm.deal(user, 100 ether);
        _;
        vm.stopPrank();
    }

    modifier anotherContract() {
        vm.startPrank(user1, anotherContractAddress);
        vm.deal(user1, 100 ether);
        _;
        vm.stopPrank();
    }
}
