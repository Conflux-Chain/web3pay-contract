import {
    attach,
    deploy,
    DEPLOY_V2_INFO,
    deployV2App,
    networkInfo,
    timestampLog,
    tokensEthFork,
    tokensNet71,
    waitTx
} from "./lib";
import {formatEther, formatUnits, parseEther} from "ethers/lib/utils";
import {ApiWeightTokenFactory, AppCoinV2, ERC1967Proxy, SwapExchange, UpgradeableBeacon} from "../typechain";
import {ethers, upgrades} from "hardhat";
import fs from "fs";

async function checkContract(addr:string) {
    console.log(`check contract at ${addr}`)
    const tmpContract = await ethers.getContractAt("SwapExchange", addr, )
    console.log(`contract is `, tmpContract)
}
async function main() {
    timestampLog()
    const  {signer, account:acc1, chainId} = await networkInfo()
    // await deployAllV2(acc1);
    // await checkContract(exchange.address);

    const {appFactoryProxy, apiWeightFactoryProxy} = JSON.parse(fs.readFileSync(DEPLOY_V2_INFO.replace(".json", `.chain-${chainId}.json`)).toString())
    await upgradeApiWeight(apiWeightFactoryProxy);
    await upgradeApp(appFactoryProxy);
}
async function upgradeApiWeight(factoryAddr:string) {
    return upgradeFactory("ApiWeightToken", [ethers.constants.AddressZero, "","",""], factoryAddr)
}
async function upgradeApp(factoryAddr:string) {
    return upgradeFactory("App", [], factoryAddr);
}
async function upgradeFactory(implName:string, argv:any[], factoryAddr:string) {
    const factory = await attach("ApiWeightTokenFactory", factoryAddr) as ApiWeightTokenFactory;
    const beacon = await factory.beacon()
    console.log(`beacon at ${beacon}`)
    return upgrade(implName, argv, beacon);
}
async function upgrade(name:string, argv:any[], beacon:string) {
    const impl = await deploy(name, argv);
    const beaconContract = await attach("UpgradeableBeacon", beacon) as UpgradeableBeacon;
    await beaconContract.upgradeTo(impl!.address);
    console.log(`upgraded ${name} ${impl!.address}`);
}
async function deployAllV2(acc1: string) {
    const {usdt, __router} = tokensNet71;
    const {v2app, exchange, appX, assetToken} = await deployV2App(usdt, __router)
    // const {v2app, exchange, vipCoin, appX} = await deployV2App(tokensEthFork.usdt, tokensEthFork.__router)
    console.log(`deploy v2 ok`)
    const acAmount = 1//parseEther("1")
    const inAmt = await exchange.previewDepositETH(acAmount);
    await exchange.depositETH(acAmount * 3, acc1, {value: inAmt.mul(3)}).then(waitTx).then(({transactionHash})=>{
        console.log(`deposit eth tx hash ${transactionHash}`)
    })
    const balance = await v2app.balanceOf(acc1);
    console.log(`app balance is ${balance} ${formatUnits(balance, 6)}, decimals ${await v2app.decimals()}`)
    await v2app.approve(exchange.address, acAmount).then(waitTx)
    console.log(`allowance`, await v2app.allowance(acc1, exchange.address))
    const {transactionHash} = await exchange.withdrawETH(acAmount, 0, acc1).then(waitTx);
    console.log(`withdraw transactionHash ${transactionHash}`)
    // deposit to appX through app coin
    await v2app.approve(appX.address, acAmount).then(waitTx)
    console.log(`allowance appx`, await v2app.allowance(acc1, appX.address), "app coin", await appX.getAppCoin())
    await appX.deposit(acAmount, acc1).then(waitTx)
    console.log(`app x balance ${await appX.balanceOf(acc1)}`)
    // deposit to app directly
    await exchange.depositAppETH(appX.address, acAmount, acc1, {value: inAmt.mul(2)}).then(waitTx);
    // withdraw base asset
    await appX.withdraw(acc1, true).then(waitTx);

    await exchange.depositAppETH(appX.address, acAmount, acc1, {value: inAmt.mul(2)}).then(waitTx);
    // withdraw
    await appX.requestForceWithdraw().then(waitTx)
    console.log(`requestForceWithdraw ok`)
    await appX.forceWithdrawEth(acc1, exchange.address, 0).then(waitTx);
    console.log(`app x balance after withdraw ${await appX.balanceOf(acc1)}`)

    console.log(`base asset balance ${await assetToken.balanceOf(acc1)}`)
    await assetToken.approve(appX.address, acAmount).then(waitTx)
    await appX.depositAsset(acAmount, acc1).then(waitTx)
}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
