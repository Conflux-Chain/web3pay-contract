import {ethers} from "hardhat";
import {ContractTransaction} from "ethers";
import {formatEther, parseEther} from "ethers/lib/utils";
import {
	ApiWeightToken, ApiWeightTokenFactory,
	App,
	AppCoinV2, AppFactory, AppRegistry,
	CardShop,
	CardTemplate,
	CardTracker, ERC1967Proxy, ERC20,
	IERC20,
	ISwap, MyERC1967,
	SwapExchange,
	TokenRouter, UpgradeableBeacon, VipCoin, VipCoinFactory
} from "../typechain";
import fs from "fs";
export const tokensNet71 = {
	usdt: "0x7d682e65efc5c13bf4e394b8f376c48e6bae0355", // net71 faucet usdt,
	ppi: "0x49916ba65d0048c4bbb0a786a527d98d10a1cd2d", // ppi
	btc: "0x54593e02c39aeff52b166bd036797d2b1478de8d", // fauct btc
	wcfx: "0x2ed3dddae5b2f321af0806181fbfa6d049be47d8",
	testApp: "0x04599b35466F23cDf7e28762E5216C6d5B4edDE5",
	__router: "0x873789aaf553fd0b4252d0d2b72c6331c47aff2e", // swappi router
}
export const tokensEthFork = {
	usdt: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
	__router: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
}
export async function attachT<T>(name:string, to:string) : Promise<T>{
	return attach(name, to).then(res=>res as any as T)
}
export async function attach(name:string, to:string) {
	const template = await ethers.getContractFactory(name);
	return template.attach(to)
}
export async function depositTokens(tokens:any, myRouter:TokenRouter, path:string[], testApp: string, base20: IERC20) {
	const swapRouter = tokens.__router //
	const useToken = await ethers.getContractAt("IERC20", path[0]) as IERC20;
	await useToken.approve(myRouter.address, parseEther("1")).then(tx => tx.wait());
	console.log(`approved`)
	await myRouter.depositWithSwap(swapRouter, parseEther("1"), 0, path, testApp, getDeadline()).then(tx => tx.wait())
	console.log(`depositWithSwap ok`)
	//
	await base20.approve(myRouter.address, parseEther("1")).then(waitTx)
	await myRouter.depositBaseToken(parseEther("1"), testApp).then(waitTx)
	console.log(`depositBaseToken. done`)

	await useToken.approve(myRouter.address, parseEther("1")).then(tx => tx.wait());
	console.log(`approved`)
	await myRouter.swapTokensForExactBaseTokens(swapRouter, parseEther("1"),
		parseEther("1"), path, testApp, getDeadline()).then(tx => tx.wait())
	console.log(`swapTokensForExactBaseTokens ok`)

	await myRouter.depositNativeValue(swapRouter, parseEther("0.03"), [tokens.wcfx, base20.address], testApp, getDeadline()
		, {value: parseEther("1")}).then(tx=>tx.wait())
	console.log(`depositNativeValue done`)
}
export async function approveERC20(token:string, to:string, amount:string) {
	const template = await ethers.getContractFactory([
		"function approve(address to, uint amount) public",
		"function name() public view returns (string)",
	], '0x');
	const contract = await template.attach(token) as IERC20
	await contract.approve(to, parseEther(amount)).then(tx=>tx.wait());
	console.log(`approve ${await (contract as any)['name']()} ${token} to ${to} x ${amount}`)
}
export async function mintERC20(token:string, to:string, amount:string) {
	const template = await ethers.getContractFactory([
		"function mint(address to, uint amount) public",
		"function name() public view returns (string)",
	], '0x');
	const contract = await template.attach(token)
	await contract['mint'](to, parseEther(amount)).then((tx:ContractTransaction)=>tx.wait())
	console.log(`mint ${await contract['name']()} ${token} to ${to} x ${amount}`)
}
export async function deployBeacon(implName:string, argv: any[]) {
	const impl = await deploy(implName, argv);
	const beacon = await deploy("UpgradeableBeacon", [impl!.address]) as UpgradeableBeacon;
	return {impl, beacon}
}
export async function deployWithBeaconProxy(implName:string, initArgv: any[]) {
	const {impl, beacon} = await deployBeacon(implName, []);

	const initReq = initArgv.length ? await impl!.populateTransaction['initialize'](...initArgv) : {data: Buffer.from("")};
	const proxy = await deploy("BeaconProxy", [beacon?.address, initReq!.data])
	const instance = await attach(implName, proxy!.address);
	return {impl, proxy, instance, beacon}
}
export async function deployWith1967Proxy(implName:string, initArgv: any[]) {
	const impl = await deploy(implName, []);
	const initReq = initArgv.length ? await impl!.populateTransaction['initialize'](...initArgv) : {data: Buffer.from("")};
	const proxy = await deploy("ERC1967Proxy", [impl?.address, initReq!.data])
	const instance = await attach(implName, proxy!.address);
	return {impl, proxy, instance}
}
export const DEPLOY_V2_INFO = `./artifacts/deploy-v2.json.txt`
export async function deployV2App(asset: string, swap:string) {
	console.log(`use asset ${asset}`)
	const v2app = await deploy("AppCoinV2", [asset]) as AppCoinV2;
	const appOwner = await v2app.signer.getAddress();
	// proxy exchange
	const {impl: exchangeImpl, proxy: exProxy, instance: exchangeInst, beacon: exchangeBeacon} = await deployWithBeaconProxy("SwapExchange", [v2app.address, swap]);
	const exchange = await attach("SwapExchange", exchangeInst.address) as SwapExchange;


	const apiWeightTokenImpl = await deploy("ApiWeightToken", [ethers.constants.AddressZero, "", "", ""]) as ApiWeightToken;
	const {instance: apiWeightFactory, impl: apiWeightFactoryImpl, beacon: apiWeightFactoryBeacon} = await deployWithBeaconProxy("ApiWeightTokenFactory",
		[apiWeightTokenImpl.address, appOwner]
	);
	const apiWeightTokenBeacon = await (apiWeightFactory as ApiWeightTokenFactory).beacon();

	const {instance: vipCoinFactory, impl: vipCoinFactoryImpl, beacon: vipCoinFactoryBeacon} = await deployWithBeaconProxy("VipCoinFactory", []);

	const {impl: cardTemplateImpl, beacon: cardTemplateBeacon} = await deployBeacon("CardTemplate", []);
	const {impl: cardTrackerImpl, beacon: cardTrackerBeacon} = await deployBeacon("CardTracker", [ethers.constants.AddressZero]);
	const {impl: cardShopImpl, beacon: cardShopBeacon} = await deployBeacon("CardShop",[]);

	const {proxy:cardShopFactoryProxy, impl:carShopFactoryImpl, beacon: cardShopFactoryBeacon} = await deployWithBeaconProxy("CardShopFactory",
		[cardShopBeacon.address, cardTemplateBeacon.address, cardTrackerBeacon.address])

	const {impl: appImpl, beacon: appBeacon} = await deployBeacon("App",[]);
	const {proxy:appFactoryProxy, instance: appFactoryInst, impl:appFactoryImpl, beacon: appFactoryBeacon} = await deployWithBeaconProxy("AppFactory",
		[v2app.address, vipCoinFactory.address, apiWeightFactory.address, cardShopFactoryProxy?.address, appBeacon.address])
	const appUpBeacon = appBeacon;

	const {instance: appRegistryInst, impl: appRegistryImpl, beacon: appRegFactoryBeacon} =
		await deployWithBeaconProxy("AppRegistry", [appFactoryProxy!.address, exchange.address])
	const {instance:readFunctionsProxy, beacon: readFunctionsBeacon} = await deployWithBeaconProxy("ReadFunctions", [appRegistryInst.address]);

	console.log(`deploy ok, create app now...`)
	const appRegistry = appRegistryInst as AppRegistry;
	await appRegistry.create("app x", "appX", "my link", "my desc", 1, 0, 1, appOwner).then(waitTx);
	const [total, createdList] = await appRegistry.listByOwner(appOwner, 0, 100)
	const lastApp = createdList[createdList.length - 1];
	//
	const appX = await attach("App", lastApp.addr) as App
	const vipCoinAddr = await appX.getVipCoin()
	const vipCoin = await attach("VipCoin", vipCoinAddr) as VipCoin;
	const assetToken = await attach("ERC20", asset) as ERC20;

	const deployInfo = {
		AppCoinV2: v2app.address,

		exchangeImpl: exchangeImpl!.address,		exchangeProxy: exchange.address, exchangeBeacon: exchangeBeacon.address,

		apiWeightTokenImpl: apiWeightTokenImpl.address, apiWeightTokenBeacon,

		apiWeightFactoryBeacon: apiWeightFactoryBeacon.address,
		apiWeightFactoryImpl: apiWeightFactoryImpl?.address, apiWeightFactoryProxy: apiWeightFactory.address,

		vipCoinFactoryImpl: vipCoinFactoryImpl?.address, vipCoinFactoryProxy: vipCoinFactory.address, vipCoinFactoryBeacon: vipCoinFactoryBeacon.address,

		cardTemplateImpl: cardTemplateImpl!.address, cardTrackerImpl: cardTrackerImpl!.address, cardShopImpl:cardShopImpl!.address,
		cardTemplateBeacon:cardTemplateBeacon!.address, cardTrackerBeacon:cardTrackerBeacon!.address, cardShopBeacon:cardShopBeacon!.address,

		carShopFactoryImpl:carShopFactoryImpl!.address, cardShopFactoryProxy:cardShopFactoryProxy!.address,
		cardShopFactoryBeacon: cardShopFactoryBeacon.address,

		appImpl:appImpl?.address, appUpgradableBeacon: appUpBeacon.address,

		appFactoryImpl: appFactoryImpl?.address, appFactoryProxy: appFactoryProxy?.address, appFactoryBeacon:appFactoryBeacon.address,

		appRegistryImpl: appRegistryImpl?.address, appRegistryProxy: appRegistryInst.address, appRegFactoryBeacon:appRegFactoryBeacon.address,
		readFunctionsProxy: readFunctionsProxy.address, readFunctionsBeacon: readFunctionsBeacon.address,
		testApp: appX.address,
	}
	const {chainId} = await ethers.provider.getNetwork()
	await fs.writeFileSync(DEPLOY_V2_INFO.replace(".json", `.chain-${chainId}.json`), JSON.stringify(deployInfo, null, 4))
	return {v2app, exchange, vipCoin, appX, assetToken};
}

export async function networkInfo() {
	const [signer] = await ethers.getSigners()
	const acc1 = signer.address

	let network = await ethers.provider.getNetwork();
	console.log(`${acc1} balance `, await signer.getBalance().then(formatEther), `network`, network)
	const {chainId} = network;
	return {signer, account: acc1, chainId}
}
export function getDeadline(diff: number = 1000) {
	return Math.round(Date.now()/1000 ) + diff
}
export function waitTx(tx:any) {
	return tx.wait();
}
export async function sleep(ms:number) {
	return new Promise(r=>setTimeout(r, ms))
}
export function timestampLog() {
	const rawLog = console.log;
	console.log = function () {
		process.stdout.write(new Date().toISOString())
		process.stdout.write(' ')
		// @ts-ignore
		rawLog.apply(console, arguments);
	}
}
export async function deploy(name:string, args:any[]) {
	// We get the contract to deploy
	const Factory = await ethers.getContractFactory(name).catch(err=>{
		console.log(`error getContractFactory`, err)
	});
	if (!Factory) {
		return;
	}
	const deployer = await Factory.deploy(...args,
	).catch(err=>{
		console.log(`error deploy ${name}.`, err)
		console.log(`more info `, err.code, err.message, err.data)
	});
	if (!deployer) {
		return;
	}
	const instance = await deployer.deployed();

	console.log(name+" deployed to:", deployer.address);
	return instance;
}