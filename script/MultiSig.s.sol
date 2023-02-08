// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "../src/MultiSig.sol";

contract MultiSigScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address[] memory signers = new address[](1);

        signers[0] = 0x2B68407d77B044237aE7f99369AA0347Ca44B129;

        MultiSig ms = new MultiSig(signers, 1);

        vm.stopBroadcast();
    }
}
