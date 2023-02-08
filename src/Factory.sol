// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./MultiSig.sol";

contract Factory {

    event NewMultiSig(address);

    function buildMultiSig(address[] memory _signers, uint256 _quorum) public {
        MultiSig ms = new MultiSig(_signers, _quorum);
        emit NewMultiSig(address(ms));
    }
}