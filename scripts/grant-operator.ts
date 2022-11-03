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
    await grant();
}

async function grantRoles(app: string, operator: string) {
    const appX = await ethers.getContractAt("App", app).then(res=>res as App)
    await appX.grantRole(ethers.utils.keccak256(Buffer.from("AIRDROP_ROLE")), operator);
    await appX.grantRole(ethers.utils.keccak256(Buffer.from("CONFIG_ROLE")), operator);
    await appX.grantRole(ethers.utils.keccak256(Buffer.from("CHARGE_ROLE")), operator);
    console.log(`granted , to ${operator}`)
}

async function grant() {
    let tag = '-prod';// deployment info file uses tag;
    console.log(`use tag [${tag}]`)
    const {signer, account: acc1, chainId} = await networkInfo()

    // replace placeholder
    await grantRoles("app", "operator");
}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});