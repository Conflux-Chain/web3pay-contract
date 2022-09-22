import {ethers, upgrades} from "hardhat";
import {
    Cards, CardShop, CardTemplate, CardTracker
} from "../typechain";
const {parseEther, formatEther} = ethers.utils
import {verifyContract} from "./verify-scan";
import {
    approveERC20,
    attach,
    deploy, DEPLOY_CARD_INFO, deployCardContracts,
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
    await deployCardContracts();
    await mint();
}
async function attachShop() {
    const {shop:shopAt, cards:instAt, template:templateAt, tracker:trackerAt} = JSON.parse(fs.readFileSync(DEPLOY_CARD_INFO).toString())
    const inst = await attach("Cards", instAt) as Cards
    const template = await attach("CardTemplate", templateAt) as CardTemplate
    const shop = await attach("CardShop", shopAt) as CardShop
    const tracker = await attach("CardTracker", trackerAt) as CardTracker
    return {shop, template, inst, tracker}
}

async function mint() {
    const {shop, template, inst} = await attachShop();
    // const {shop, template, inst} = await deployCardContracts();
    //
    await template.config({
        description: "这是一个测试描述😂",
        duration: 3600,
        icon: "/favicon.ico",
        id: 0,
        level: 1,
        name: "name名称",
        price: 1,
        status: 0
    }).then(waitTx)
    const {transactionHash} = await shop.buy(1).then(waitTx)
    console.log(`buy card tx hash ${transactionHash}`)
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});