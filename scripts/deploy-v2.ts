import {
    attach,
    deploy,
    DEPLOY_V2_INFO,
    deployV2App,
    networkInfo, sleep,
    timestampLog,
    tokensEthFork,
    tokensNet71,
    waitTx
} from "./lib";
import {formatEther, formatUnits, parseEther} from "ethers/lib/utils";
import {
    ApiWeightToken,
    ApiWeightTokenFactory,
    AppCoinV2, AppRegistry,
    CardShop,
    CardTemplate, CardTracker,
    ERC1967Proxy,
    SwapExchange,
    UpgradeableBeacon
} from "../typechain";
import {ethers, upgrades} from "hardhat";
import fs from "fs";
import {verifyContract} from "./verify-scan";

async function checkContract(addr:string) {
    console.log(`check contract at ${addr}`)
    const tmpContract = await ethers.getContractAt("SwapExchange", addr, )
    console.log(`contract is `, tmpContract)
}

async function setCreatorRoleDisabled(chainId:any, flag: boolean) {
    const {appRegistryProxy} = JSON.parse(fs.readFileSync(DEPLOY_V2_INFO.replace(".json", `.chain-${chainId}.json`)).toString())
    const registry = await attach("AppRegistry", appRegistryProxy) as AppRegistry
    const {transactionHash} = await registry.setCreatorRoleDisabled(flag).then(waitTx)
    console.log(`ok `, transactionHash)
}

async function main() {
    timestampLog()
    const  {signer, account:acc1, chainId} = await networkInfo()
    // await deployAllV2(acc1);
    // await setCreatorRoleDisabled(chainId, true);
    // await checkContract(exchange.address);

    const {appRegistryProxy, apiWeightFactoryProxy,appRegFactoryBeacon, appFactoryBeacon, appUpgradableBeacon} = JSON.parse(fs.readFileSync(DEPLOY_V2_INFO.replace(".json", `.chain-${chainId}.json`)).toString())
    // await upgradeApiWeight(apiWeightFactoryProxy);
    // await upgradeBeacon("AppRegistry", [], appRegFactoryBeacon);
    // await upgradeBeacon("AppFactory", [], appFactoryBeacon);
    // await upgradeBeacon("App", [], appUpgradableBeacon);
    // await upgradeFactory()
    // await createApp(appRegistryProxy, acc1);
}
async function createApp(appRegistryProxy:string, acc:string) {
    console.log(`appRegistryProxy ${appRegistryProxy}`)
    const registry = await attach("AppRegistry", appRegistryProxy) as AppRegistry;
    const {transactionHash} = await registry.create("name 1", "symbol 1", "link 2", "desc 3", 2, 0, 5, acc).then(waitTx)
    console.log(`create ok ${transactionHash}`)
}
async function upgradeFactory(name: string, proxyAddr: string) {
    const impl_ = await deploy(name, []);
    const proxy = await attach("ERC1967Proxy", proxyAddr) as ERC1967Proxy;
    // await proxy.
}
async function upgradeApiWeight(factoryAddr:string) {
    return upgradeBeaconInFactory("ApiWeightToken", [ethers.constants.AddressZero, "","",""], factoryAddr)
}
async function upgradeApp(factoryAddr:string) {
    return upgradeBeaconInFactory("App", [], factoryAddr);
}
async function upgradeBeaconInFactory(implName:string, argv:any[], factoryAddr:string) {
    //                                  This name only stands for `beacon()` interface.
    const factory = await attach("ApiWeightTokenFactory", factoryAddr) as ApiWeightTokenFactory;
    const beacon = await factory.beacon()
    console.log(`beacon at ${beacon}`)
    return upgradeBeacon(implName, argv, beacon);
}
async function upgradeBeacon(name:string, argv:any[], beacon:string) {
    const impl = await deploy(name, argv);
    const beaconContract = await attach("UpgradeableBeacon", beacon) as UpgradeableBeacon;
    await beaconContract.upgradeTo(impl!.address);
    console.log(`upgraded ${name} ${impl!.address}`);
    //await sleep(9_000);// wait scan syc
    //await verifyContract(name, impl?.address!);
}
async function deployAllV2(acc1: string) {
    const {usdt, __router} = tokensNet71;
    const {v2app, exchange, appX, assetToken} = await deployV2App(usdt, __router)
    // const {v2app, exchange, vipCoin, appX} = await deployV2App(tokensEthFork.usdt, tokensEthFork.__router)
    console.log(`deploy v2 ok`)
    const acAmount = 10000//parseEther("1")
    const inAmt = await exchange.previewDepositETH(acAmount);
    await exchange.depositETH(acAmount * 3, acc1, {value: inAmt.mul(3)}).then(waitTx).then(({transactionHash})=>{
        console.log(`deposit eth tx hash ${transactionHash}`)
    })
    const balance = await v2app.balanceOf(acc1);
    let decimals = await v2app.decimals();
    console.log(`app balance is ${balance} ${formatUnits(balance, decimals)}, decimals ${decimals}`)
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

    // card
    const shop = await attach("CardShop", await appX.cardShop()) as CardShop;
    const template = await attach("CardTemplate", await shop.template()) as CardTemplate;
    const tracker = await attach("CardTracker", await shop.tracker()) as CardTracker;
    await template.config({
        closeSaleAt: 0, description: "", duration: 1, icon: "/favicon.ico", id: 0,// will auto generate
        level: 1, listPrice: 2, name: "test card", openSaleAt: 3, price: 4, salesLimit: 5, status: 1
    }).then(waitTx)
    const templateId = await template.nextId().then(res=>res.sub(1));
    console.log(`config card template ok, id ${templateId} level `, await template.getTemplate(templateId).then(res=>res.level));
    await shop.buy(acc1, templateId).then(waitTx)
    console.log(`buy card ok`)
    console.log(`vip level`, await tracker.getVipInfo(acc1).then(({expireAt, level})=>`level ${level} expireAt ${expireAt}`))
    // config
    const apiConfig = await appX.getApiWeightToken().then(res=>attach("ApiWeightToken", res)).then(res=>res as ApiWeightToken)
    await apiConfig.setPendingSeconds(0).then(waitTx);
    console.log(`set setPendingSeconds ok`)
    await apiConfig.configResource({id: 0, op: 0, resourceId: "test-api-w", weight: 3}).then(waitTx);
    console.log(`configResource ok`)
    await apiConfig.flushPendingConfig().then(waitTx)
    console.log(`flushPendingConfig ok, weight `, await apiConfig.listResources(0, 9).then(res=>res[0]).then(list=>list[1].weight))
    // charge
    await appX.chargeBatch([{account: acc1, amount: 1, data: Buffer.from(""),
        useDetail: [{id: 0, times: 1}]}]).then(waitTx)
    console.log(`charge ok`)
}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
