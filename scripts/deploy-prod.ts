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
    ERC1967Proxy, ERC20, ReadFunctions,
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
    await deployContracts();
}

async function createConfuraApp(testApp:string, appRegistryProxy:string, admin:string) {
    testApp = await createApp(appRegistryProxy, admin, 2, {
        name: "Confura RPC Pro-Service",
        symbol: "CFXRPC",
        link: "https://developer.confluxnetwork.org/sdks-and-tools/en/conflux_rpcs",
        description: "Confura RPC provides simple, instant, stable access to the Conflux network, services to read and write data, and execute your smart contracts.",
    });
}

async function createScanApp(testApp:string, appRegistryProxy:string, admin: string) {
    testApp = await createApp(appRegistryProxy, admin, 2, {
        name: "ConfluxScan API Pro-Service", symbol: "CFXAPI", link: "https://api-testnet.confluxscan.io/doc",
        description: "ConfluxScan is the leading blockchain explorer, search, analytics platform and developer API  for Conflux Block Chain. You can quickly build reliable and precises APPs with Conflux Scan APIs, and you can choose a plan that is right for your project's needs. ",
    });
    return testApp;
}

async function deployContracts() {
    let tag = '-prod';// deployment info file uses tag;
    console.log(`use tag [${tag}]`)
    const {signer, account: acc1, chainId} = await networkInfo()
    const {usdt, __router} = {usdt: "0xfe97e85d13abd9c1c33384e796f10b73905637ce",
        __router: "0x62b0873055bf896dd869e172119871ac24aea305"};
    await deployV2App(usdt, __router, tag)

    let {cardTemplateBeacon, cardTrackerBeacon, cardShopBeacon, exchangeProxy, readFunctionsProxy, readFunctionsBeacon, testApp,
        appRegistryProxy, apiWeightFactoryProxy,appRegFactoryBeacon, appFactoryBeacon, appUpgradableBeacon, vipCoinFactoryBeacon,
        vipCoinFactoryProxy, AppCoinV2:appCoinAddr,
    } = JSON.parse(fs.readFileSync(DEPLOY_V2_INFO.replace(".json", `.chain-${chainId}${tag}.json`)).toString())

    testApp = await createScanApp(testApp, appRegistryProxy, acc1);
    await createConfuraApp(testApp, appRegistryProxy, acc1);
    console.log(`ok.`)
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});