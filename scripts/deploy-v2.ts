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
import {base64, formatEther, formatUnits, parseEther} from "ethers/lib/utils";
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

async function checkContract(addr:string) {
    console.log(`check contract at ${addr}`)
    const tmpContract = await ethers.getContractAt("SwapExchange", addr, )
    console.log(`contract is `, tmpContract)
}

async function setCreatorRoleDisabled(appRegistryProxy:string, flag: boolean) {
    const registry = await attach("AppRegistry", appRegistryProxy) as AppRegistry
    const {transactionHash} = await registry.setCreatorRoleDisabled(flag).then(waitTx)
    console.log(`ok `, transactionHash)
}

async function testVipCardOfApp(appRegistryProxy: string, acc1: string, testApp: any) {
    await attach("App", testApp).then(res => res as App)
        .then(app => vipCardTest(app, acc1))
}

async function main() {
    timestampLog()
    let tag = '';// deployment info file uses tag;
    console.log(`use tag [${tag}]`)
    const  {signer, account:acc1, chainId} = await networkInfo()
    // const {usdt, __router} = tokensNet71;
    // await deployV2App(usdt, __router, tag)

    let {cardTemplateBeacon, cardTrackerBeacon, cardShopBeacon, exchangeProxy, readFunctionsProxy, readFunctionsBeacon, testApp,
        appRegistryProxy, apiWeightFactoryProxy,appRegFactoryBeacon, appFactoryBeacon, appUpgradableBeacon, vipCoinFactoryBeacon,
        vipCoinFactoryProxy, AppCoinV2:appCoinAddr,
    } = JSON.parse(fs.readFileSync(DEPLOY_V2_INFO.replace(".json", `.chain-${chainId}${tag}.json`)).toString())

    // await setCreatorRoleDisabled(appRegistryProxy, true);
    // await testAllV2(acc1, appCoinAddr, exchangeProxy, appRegistryProxy);
    // await deployWithBeaconProxy("ReadFunctions", [appRegistryProxy]);
    // await upgradeBeacon("ReadFunctions", [], readFunctionsBeacon);
    // await upgradeBeacon("AppRegistry", [], appRegFactoryBeacon);
    // await upgradeBeacon("AppFactory", [], appFactoryBeacon);
    // await upgradeBeacon("VipCoinFactory", [], vipCoinFactoryBeacon);
    // await upgradeBeacon("App", [], appUpgradableBeacon);
    // await upgradeBeacon("CardTracker", [ethers.constants.AddressZero], cardTrackerBeacon);
    // await upgradeBeacon("CardTemplate", [], cardTemplateBeacon);
    // await upgradeBeacon("CardShop", [], cardShopBeacon);

    // testApp = await createApp(appRegistryProxy, acc1);
    // await testVipCardOfApp(appRegistryProxy, acc1, testApp);
    // await testVipCardOfApp(appRegistryProxy, acc1, "0x607362A5326A2F9Eede7678c32A75aBA8b91486F");
    // await testReadFunctions(readFunctionsProxy, acc1);
    // testApp = await createApp(appRegistryProxy, acc1, 1); // type 1 is billing
    // await testDeposit(testApp, acc1);
    // await clearAllApps(appRegistryProxy);
}
export async function testReadRoles(appAddr: string, readFnsAddr:string) {
    const reader = await attachT<ReadFunctions>("ReadFunctions", readFnsAddr);
    const rolesInfo = await reader.appRoles(appAddr)
    console.log(`roles info`, rolesInfo)
}
export async function testSetAppInfo(appAddr:string) {
    const app = await attachT<App>("App", appAddr);
    await app.setAppInfo("link", "desc", Date.now()).then(waitTx)
    console.log(`set app info ok`)
    const adminRole = await app.DEFAULT_ADMIN_ROLE();
    await app.revokeRole(adminRole, await app.signer.getAddress())
        .then(waitTx) // should revert
        .catch(e=>{
            console.log(`ok ${e.message}`)
        })
}
async function clearAllApps(appRegistryProxy:string) {
    //let registry = await attachT<AppRegistry>("AppRegistry", appRegistryProxy);
    //await registry.remove("").then(waitTx)
}
async function testReadFunctions(readFunctionsAddr: string, account: string) {
    console.log(`readFunctionsAddr`, readFunctionsAddr);
    const readFunctionsProxy = await attachT<ReadFunctions>("ReadFunctions", readFunctionsAddr)
    const {total, apps} = await readFunctionsProxy.listAppByUser(account, 0, 99);
    console.log(`apps ${JSON.stringify(apps, null, 4)}`)
}

export async function testDeposit(appAddr: string, account: string) {
    console.log(`app is ${appAddr}`)
    const appX = await attachT<App>("App", appAddr);
    const u = await getAsset(appX);
    await depositAsset(await attachT<ERC20>("ERC20", u), account, appX, BigInt(3))

    await appX.airdrop(account, 1).then(waitTx)
}
export async function createApp(appRegistryProxy:string, owner:string, payType = 2, param: any = {}) {
    console.log(`appRegistryProxy ${appRegistryProxy}`)
    const registry = await attach("AppRegistry", appRegistryProxy) as AppRegistry;
    const {name, symbol, link, description } = param;
    let finalName = name ||"name 1";
    const {transactionHash} = await registry.create(finalName, symbol || "symbol 1",
        link || "link 2", description|| "desc 3",
        payType, 3600, 1, owner).then(waitTx)
    const [total, list] = await registry.listByOwner(owner, 0, 100)
    let addr = list[list.length-1].addr;
    console.log(`create ok tx ${transactionHash}, \n `, addr, finalName)
    return addr;
}
export async function lastApp(appRegistryProxy:string) {
    const registry = await attach("AppRegistry", appRegistryProxy) as AppRegistry;
    let me = await registry.signer.getAddress();
    const [total, list] = await registry.listByOwner(me, 0, 1000)
    let addr = list[list.length-1].addr;
    console.log(`last app is `, addr)
    return addr;
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
export async function upgradeBeacon(name:string, argv:any[], beacon:string) {
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

async function getAsset(appX: App) {
    const asset = await appX.getAppCoin().then(appCoin => attach("AppCoinV2", appCoin)).then(c => c as AppCoinV2).then(ap => ap.asset());
    return asset;
}

async function vipCardTest(appX: App, acc1: string) {
    console.log(`app is ${appX.address}`)
    const shop = await attach("CardShop", await appX.cardShop()) as CardShop;
    const template = await attach("CardTemplate", await shop.template()) as CardTemplate;
    const tracker = await attach("CardTracker", await shop.tracker()) as CardTracker;
    const tid = await template.nextId();
    let tpl = {
        description: "", duration: 1, id: 0 , giveawayDuration: 31,// will auto generate
        name: `Standard/month`, price: 1, props: {keys: ["Level"], values: ["1"]}
    };
    await template.config(tpl).then(waitTx)
    const templateId = await template.nextId().then(res => res.sub(1));
    console.log(`config card template ok, id ${templateId} props `, await template.getTemplate(templateId).then(res => res.props));
    //
    const asset = await getAsset(appX);
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

async function depositAsset(assetToken: ERC20, acc1: string, appX: App, acAmount: bigint) {
    console.log(`base asset balance ${await assetToken.balanceOf(acc1)}`)
    await mintERC20(assetToken.address, acc1, formatEther(acAmount));
    await assetToken.approve(appX.address, acAmount).then(waitTx)
    const {transactionHash} = await appX.depositAsset(acAmount, acc1).then(waitTx)
    console.log(`deposit asset ok ${transactionHash}`)
}

export async function testAllV2(acc1: string, v2appCoinAddr: string, exchangeAddr:string, appRegistryAddr: string) {
    const v2app = await attachT<AppCoinV2>("AppCoinV2", v2appCoinAddr);
    const assetToken = await v2app.asset().then(res=>attachT<ERC20>("ERC20", res));
    const exchange = await attachT<SwapExchange>("SwapExchange", exchangeAddr);
    const testAppAddr = await createApp(appRegistryAddr, acc1, 1);// 1 is billing
    const appX = await attachT<App>("App", testAppAddr);
    await appX.setDeferTimeSecs(0).then(waitTx)
    const acAmount = 1_000_000_000_000_000//parseEther("1")
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

    await forceWithdrawEth(exchange, appX, acAmount, acc1, inAmt).then(()=>{
        console.log(`forceWithdrawEth ok`)
    }).catch(err=>{
        console.log(`forceWithdrawEth fail.`, err)
    });

    await depositAsset(assetToken, acc1, appX, parseEther("1").toBigInt());
    await appX.airdrop(acc1, 1).then(waitTx)

    // card
    await vipCardTest(appX, acc1).catch(e=>{
        console.log(`vipCardTest fail`, e)
    });
    // config
    const apiConfig = await appX.getApiWeightToken().then(res=>attach("ApiWeightToken", res)).then(res=>res as ApiWeightToken)
    await apiConfig.setPendingSeconds(0).then(waitTx);
    console.log(`set setPendingSeconds ok`)
    await apiConfig.configResource({id: 0, op: 0, resourceId: "test-api-w", weight: 3}).then(waitTx);
    console.log(`configResource ok`)
    await apiConfig.flushPendingConfig().then(waitTx)
    console.log(`flushPendingConfig ok, weight `, await apiConfig.listResources(0, 9).then(res=>res[0]).then(list=>list[1].weight))
    // charge
    await appX.chargeBatch([{account: acc1, amount: parseEther("0.9"), data: Buffer.from(""),
        useDetail: [{id: 0, times: 10}]}]).then(waitTx)
    console.log(`charge ok`)

    console.log(`profit ${await appX.totalCharged()}, taken ${await appX.totalTakenProfit()}`)
    await appX.takeProfit(acc1, 1).then(waitTx).then(()=>{
        console.log(`takeProfit ok`)
    }).catch(e=>{
        console.log(`takeProfit fail`, e)
    })
    console.log(`profit ${await appX.totalCharged()}, taken ${await appX.totalTakenProfit()}`)
    await appX.takeProfitAsEth(parseEther("0.9"), 0).then(waitTx).then(()=>{
        console.log(`takeProfitAsEth ok`)
    }).catch(e=>{
        console.log(`takeProfitAsEth fail`, e)
    })
}
if (module === require.main) {
    main().catch((error) => {
        console.error(error);
        process.exitCode = 1;
    });
}
