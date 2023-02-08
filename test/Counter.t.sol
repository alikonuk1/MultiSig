// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../src/MultiSig.sol";
import "../src/Factory.sol";

contract MultiSigTest is Test {
    MultiSig public multiSig;
    Factory public factory;

    function setUp() public {
        factory = new Factory();
    }

}
