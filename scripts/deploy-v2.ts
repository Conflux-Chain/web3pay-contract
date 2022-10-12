import {
    approveERC20,
    attach, attachT,
    deploy,
    DEPLOY_V2_INFO,
    deployV2App, mintERC20,
    networkInfo, sleep,
    timestampLog,
    tokensEthFork,
    tokensNet71,
    waitTx
} from "./lib";
import {formatEther, formatUnits, parseEther} from "ethers/lib/utils";
import {
    ApiWeightToken,
    ApiWeightTokenFactory, App,
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
import {BigNumber} from "ethers";

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

async function testVipCardOfApp(appRegistryProxy:string, acc1: string) {
    await attach("AppRegistry", appRegistryProxy).then(res => res as AppRegistry)
        // .then(reg=>createApp(reg.address, acc1).then(()=>reg))
        .then(reg => reg.list(0, 99))
        // .then(appList=>{console.log(`app list`, appList); return appList;})
        .then(arr => arr[1]).then(arr => arr[arr.length - 1].addr).then(addr => attach("App", addr)).then(res => res as App)
        .then(app => vipCardTest(app, acc1))
}

async function main() {
    timestampLog()
    const  {signer, account:acc1, chainId} = await networkInfo()
    // await deployAllV2(acc1);
    // await setCreatorRoleDisabled(chainId, true);
    // await checkContract(exchange.address);

    const {cardTemplateBeacon, cardTrackerBeacon, cardShopBeacon, exchangeProxy,
        appRegistryProxy, apiWeightFactoryProxy,appRegFactoryBeacon, appFactoryBeacon, appUpgradableBeacon
    } = JSON.parse(fs.readFileSync(DEPLOY_V2_INFO.replace(".json", `.chain-${chainId}.json`)).toString())

    // await upgradeBeacon("AppRegistry", [], appRegFactoryBeacon);
    // attachT<AppRegistry>("AppRegistry", appRegistryProxy).then(res=>res.setExchanger(exchangeProxy)).then(waitTx)
    // await upgradeBeacon("AppFactory", [], appFactoryBeacon);
    // await upgradeBeacon("App", [], appUpgradableBeacon);
    // await upgradeBeacon("CardTracker", [ethers.constants.AddressZero], cardTrackerBeacon);
    // await upgradeBeacon("CardTemplate", [], cardTemplateBeacon);
    // await upgradeBeacon("CardShop", [], cardShopBeacon);
    // await testVipCardOfApp(appRegistryProxy, acc1);

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
    setTimeout(()=>{
        verifyContract(name, impl?.address!);
    }, 10_000);
}

async function depositWithdrawETH(v2app: AppCoinV2, exchange: SwapExchange, acAmount: number, acc1: string) {
    await v2app.approve(exchange.address, acAmount).then(waitTx)
    console.log(`allowance for exchange before withdrawETH`, await v2app.allowance(acc1, exchange.address))
    const {transactionHash} = await exchange.withdrawETH(acAmount, 0, acc1).then(waitTx);
    console.log(`withdraw eth transactionHash ${transactionHash}`)
}

async function depositWithdrawBaseToken(v2app: AppCoinV2, appX: App, acAmount: number, acc1: string, exchange: SwapExchange, inAmt: BigNumber) {
    await v2app.approve(appX.address, acAmount).then(waitTx)
    console.log(`allowance appx`, await v2app.allowance(acc1, appX.address), "app coin", await appX.getAppCoin())
    await appX.deposit(acAmount, acc1).then(waitTx)
    console.log(`app x balance ${await appX.balanceOf(acc1)}`)
    // deposit to app directly
    await exchange.depositAppETH(appX.address, acAmount, acc1, {value: inAmt.mul(2)}).then(waitTx);
    // withdraw base asset
    await appX.withdraw(acc1, true).then(waitTx);
}

async function forceWithdrawEth(exchange: SwapExchange, appX: App, acAmount: number, acc1: string, inAmt: BigNumber) {
    await exchange.depositAppETH(appX.address, acAmount, acc1, {value: inAmt.mul(2)}).then(waitTx);
    // withdraw
    await appX.requestForceWithdraw().then(waitTx)
    console.log(`requestForceWithdraw ok`)
    await appX.forceWithdrawEth(acc1, exchange.address, 0).then(waitTx);
    console.log(`app x balance after withdraw ${await appX.balanceOf(acc1)}`)
}

async function vipCardTest(appX: App, acc1: string) {
    console.log(`app is ${appX.address}`)
    const shop = await attach("CardShop", await appX.cardShop()) as CardShop;
    const template = await attach("CardTemplate", await shop.template()) as CardTemplate;
    const tracker = await attach("CardTracker", await shop.tracker()) as CardTracker;
    let tpl = {
        description: "", duration: 1, id: 0, giveawayDuration: 2,// will auto generate
        name: "test card", price: 4, props: {keys: ["level"], values: ["1"]}
    };
    await template.config(tpl).then(waitTx)
    const templateId = await template.nextId().then(res => res.sub(1));
    console.log(`config card template ok, id ${templateId} props `, await template.getTemplate(templateId).then(res => res.props));
    //
    const asset = await appX.getAppCoin().then(appCoin=>attach("AppCoinV2", appCoin)).then(c=>c as AppCoinV2).then(ap=>ap.asset());
    let buyCount = 3;
    let totalPrice = (tpl.price * buyCount).toString();
    await mintERC20(asset, acc1, totalPrice)
    await approveERC20(asset, shop.address, totalPrice)
    const {transactionHash} = await shop.buyWithAsset(acc1, templateId, buyCount).then(waitTx)
    console.log(`buy card ok ${transactionHash}`)
    console.log(`vip info`, await tracker.getVipInfo(acc1).then(({expireAt, props}) => `expireAt ${expireAt} props ${props}`))
    // buy with eth
    const {transactionHashEth} = await shop.buyWithEth(acc1, templateId, buyCount, {value: tpl.price * buyCount + 12345 }).then(waitTx)
    console.log(`buy with eth ok ${transactionHashEth}`)
    console.log(`vip info`, await tracker.getVipInfo(acc1).then(({expireAt, props}) => `expireAt ${expireAt} props ${props}`))
}

async function deployAllV2(acc1: string) {
    const {usdt, __router} = tokensNet71;
    const {v2app, exchange, appX, assetToken} = await deployV2App(usdt, __router)
    // const {v2app, exchange, vipCoin, appX} = await deployV2App(tokensEthFork.usdt, tokensEthFork.__router)
    console.log(`deploy v2 ok`)
    const acAmount = 100000//parseEther("1")
    const inAmt = await exchange.previewDepositETH(acAmount);
    await exchange.depositETH(acAmount * 3, acc1, {value: inAmt.mul(3)}).then(waitTx).then(({transactionHash})=>{
        console.log(`deposit eth tx hash ${transactionHash}`)
    })
    const balance = await v2app.balanceOf(acc1);
    let decimals = await v2app.decimals();
    console.log(`app balance is ${balance} ${formatUnits(balance, decimals)}, decimals ${decimals}`)
    await depositWithdrawETH(v2app, exchange, acAmount, acc1).catch(err=>{
        console.log(`depositWithdrawETH fail.`, err)
    });
    // deposit to appX through app coin
    await depositWithdrawBaseToken(v2app, appX, acAmount, acc1, exchange, inAmt).catch(err=>{
        console.log(`depositWithdrawBaseToken fail.`, err)
    });

    await forceWithdrawEth(exchange, appX, acAmount, acc1, inAmt).catch(err=>{
        console.log(`forceWithdrawEth fail.`, err)
    });

    console.log(`base asset balance ${await assetToken.balanceOf(acc1)}`)
    await assetToken.approve(appX.address, acAmount).then(waitTx)
    await appX.depositAsset(acAmount, acc1).then(waitTx)

    // card
    await vipCardTest(appX, acc1);
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
