// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./BaseScript.s.sol";
import "../src/NFTMarketV1.sol";

contract NFTMarketV1Script is BaseScript {
    function run() public broadcaster {
        Options memory opts;
        // opts.unsafeSkipAllChecks = true;
        
        address proxy = Upgrades.deployTransparentProxy(
            "NFTMarketV1.sol",
            deployer,
            abi.encodeCall(
                NFTMarketV1.initialize,
                (25, 0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8)
            )
            ,opts
        );

        console.log("NFTMarketV1 deployed on %s", address(proxy));
    }
}