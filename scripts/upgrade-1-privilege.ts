import {
    approveERC20,
    attach, attachT,
    deploy,
    DEPLOY_V2_INFO,
    deployV2App, deployWithBeaconProxy, mintERC20,
    networkInfo, sleep,
    timestampLog,
    tokensEthFork,
    tokensNet71,
    waitTx
} from "./lib";
import {base64, formatEther, FormatTypes, formatUnits, Interface, parseEther} from "ethers/lib/utils";
import {
    ApiWeightToken,
    ApiWeightTokenFactory, App,
    AppCoinV2, AppRegistry,
    CardShop,
    CardTemplate, CardTracker,
    ERC1967Proxy, ERC20, ReadFunctions, Roles,
    SwapExchange,
    UpgradeableBeacon, VipCoinFactory
} from "../typechain";
import {ethers, upgrades} from "hardhat";
import fs from "fs";
import {verifyContract} from "./verify-scan";
import {BigNumber} from "ethers";
import {createApp, testAllV2, testDeposit, upgradeBeacon} from "./deploy-v2";
import {Conflux, format} from "js-conflux-sdk";

async function main() {
    timestampLog()
    await upgradePrivilege();
}

/**
 * App.setAppInfo
 * ReadFunctions.appRoles
 */
async function upgradePrivilege() {
    let tag = '-prod';// deployment info file uses tag;
    console.log(`use tag [${tag}]`)
    const {signer, account: acc1, chainId} = await networkInfo()

    let {cardTemplateBeacon, cardTrackerBeacon, cardShopBeacon, exchangeProxy, readFunctionsProxy, readFunctionsBeacon, testApp,
        appRegistryProxy, apiWeightFactoryProxy,appRegFactoryBeacon, appFactoryBeacon, appUpgradableBeacon, vipCoinFactoryBeacon,
        vipCoinFactoryProxy, AppCoinV2:appCoinAddr,
    } = JSON.parse(fs.readFileSync(DEPLOY_V2_INFO.replace(".json", `.chain-${chainId}${tag}.json`)).toString())

    await upgradeBeacon("App", [], appUpgradableBeacon);
    await upgradeBeacon("ReadFunctions", [], readFunctionsBeacon);
    console.log(`ok`)
}
main().catch((error) => {
    console.error('error in main:', error);
    process.exitCode = 1;
});