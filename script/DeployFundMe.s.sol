// SPDX-License-Identifier : MIT

pragma solidity ^0.8.18;

import {Script} from "lib/forge-std/src/Script.sol";
import "lib/forge-std/src/console.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPricefeed = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethUsdPricefeed);
        vm.stopBroadcast();
        return fundMe;
    }
}
