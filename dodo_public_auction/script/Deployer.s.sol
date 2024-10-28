// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {Auction} from "../src/PublicAuction.sol";

contract DeployerScript is Script {

    function setUp() public {}

    function run() public returns(Auction) {
        vm.startBroadcast();

        Auction publicAuction = new Auction(3600, 100);

        vm.stopBroadcast();
        return publicAuction;
    }
}
