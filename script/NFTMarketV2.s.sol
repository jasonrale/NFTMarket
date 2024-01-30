// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./BaseScript.s.sol";
import "../src/NFTMarketV2.sol";

import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract NFTMarketV2Script is BaseScript {
    function run() public broadcaster {
        Options memory opts;
        // opts.unsafeSkipAllChecks = true;
        
        address proxy = Upgrades.deployTransparentProxy(
            "NFTMarketV2.sol",
            deployer,
            abi.encodeCall(
                NFTMarketV2.initialize,
                (25, 0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8)
            )
            ,opts
        );

        console.log("Counter deployed on %s", address(proxy));
    }
}