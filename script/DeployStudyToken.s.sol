// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {StudyToken} from "../src/StudyToken.sol";

/// Local:   anvil   (in another terminal), then
///          forge script script/DeployStudyToken.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --account <keystore>
/// Sepolia: same command with --rpc-url $SEPOLIA_RPC_URL (see README, day 13).
contract DeployStudyToken is Script {
    function run() external returns (StudyToken token) {
        vm.startBroadcast();
        token = new StudyToken("Study Token", "STD", 1_000_000e18);
        vm.stopBroadcast();
        console.log("StudyToken deployed at", address(token));
    }
}
