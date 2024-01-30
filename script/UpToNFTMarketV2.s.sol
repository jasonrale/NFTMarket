// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./BaseScript.s.sol";
import "../src/NFTMarketV2.sol";

contract UpToNFTMarketV2 is BaseScript {
    function run() public broadcaster {
        // Options memory opts;
        // opts.unsafeSkipAllChecks = true;

        address proxy = 0x71E66Fb8670B66385c5D521129cA3765B662f8cd;

        address implementation = Upgrades.getImplementationAddress(proxy);
        console.log("Before upgrade address: %s", implementation);

        Upgrades.upgradeProxy( 
            proxy,
            "NFTMarketV2.sol"
            // abi.encodeCall(
            //     NFTMarketV2.initialize,
            //     (25, 0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8)
            // )
        );

        implementation = Upgrades.getImplementationAddress(proxy);
        console.log("After upgrade address: %s", implementation);
    }
}
