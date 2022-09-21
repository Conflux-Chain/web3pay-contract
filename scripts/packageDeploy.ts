import {ethers, upgrades} from "hardhat";
import {
} from "../typechain";
const {parseEther, formatEther} = ethers.utils
import {verifyContract} from "./verify-scan";
import {
    approveERC20,
    attach,
    deploy, deployCardContracts,
    depositTokens,
    getDeadline,
    mintERC20,
    networkInfo,
    sleep,
    tokensNet71, waitTx
} from "./lib";
import {ContractTransaction} from "ethers";
import * as fs from "fs";

async function main() {
    const  {signer, account:acc1} = await networkInfo()
    // await deployPkgShop()
    await mint();
}
async function attachShop() {
    let templateAt = "", instAt = "", shopAt = "";
    shopAt = "0x8454d1D17Eb0227E04B1235fB1c53C4870E69337"
    instAt = "0xE6aED4445437cA8BcA38078b0787C4840e4CeCf7";
    templateAt = "0x4d9422b4363e8cC43a4172BBA4fAeB0964BD16C5";
    const inst = await attach("PackageInstance", instAt)
    const template = await attach("PackageTemplate", templateAt)
    const shop = await attach("PackageShop", shopAt)
    return {shop, template, inst}
}

async function mint() {
    // const {shop, template, inst} = await attachShop();
    const {shop, template, inst} = await deployCardContracts();
    //
    await template.config({
        closeSaleAt: 0,
        description: "这是一个测试描述😂",
        duration: 3600,
        icon: "/favicon.ico",
        id: 0,
        level: 1,
        name: "name名称",
        openSaleAt: 0,
        price: 1,
        salesLimit: 0,
        showPrice: 100,
        status: 0
    }).then(waitTx)
    let nextId = await template.nextId()
    await shop.buy(nextId.sub(1))
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});