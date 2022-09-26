import {ethers} from "hardhat";
import {ContractTransaction} from "ethers";
import {formatEther, parseEther} from "ethers/lib/utils";
import {
	App,
	AppCoinV2, AppRegistry,
	Cards,
	CardShop,
	CardTemplate,
	CardTracker, ERC1967Proxy, ERC20,
	IERC20,
	ISwap, MyERC1967,
	SwapExchange,
	TokenRouter, VipCoin, VipCoinFactory
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
export async function deployWithProxy(implName:string, initArgv: any[]) {
	const impl = await deploy(implName, []);
	const initReq = await impl!.populateTransaction['initialize'](...initArgv);
	const proxy = await deploy("ERC1967Proxy", [impl?.address, initReq!.data])
	const instance = await attach(implName, proxy!.address);
	return {impl, proxy, instance}
}
export async function deployV2App(asset: string, swap:string) {
	console.log(`use asset ${asset}`)
	const v2app = await deploy("AppCoinV2", [asset]) as AppCoinV2;
	const appOwner = await v2app.signer.getAddress();
	// proxy exchange
	const exchangeImpl = await deploy("SwapExchange",[]) as SwapExchange;
	const initReq = await exchangeImpl.populateTransaction.initialize(v2app.address, swap);
	// await exchange.initialize(v2app.address, swap);
	const exProxy = await deploy("ERC1967Proxy", [exchangeImpl.address, initReq.data]) as ERC1967Proxy
	const exchange = await attach("SwapExchange", exProxy.address) as SwapExchange

	const vipCoinFactory = await deploy("VipCoinFactory", []) as VipCoinFactory;
	const {proxy:appFactory} = await deployWithProxy("AppFactory",
		[v2app.address, vipCoinFactory.address, appOwner])
	const {instance: appRegistryInst} = await deployWithProxy("AppRegistry", [appFactory!.address])
	console.log(`deploy ok, create app now...`)
	const appRegistry = appRegistryInst as AppRegistry;
	await appRegistry.create("app x", "appX", "uri", 0, appOwner).then(waitTx);
	const [total, createdList] = await appRegistry.listByOwner(appOwner, 0, 100)
	const lastApp = createdList[createdList.length - 1];
	//
	const appX = await attach("App", lastApp.addr) as App
	const vipCoinAddr = await appX.vipCoin()
	const vipCoin = await attach("VipCoin", vipCoinAddr) as VipCoin;
	const assetToken = await attach("ERC20", asset) as ERC20;
	return {v2app, exchange, vipCoin, appX, assetToken};
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
export async function networkInfo() {
	const [signer] = await ethers.getSigners()
	const acc1 = signer.address

	let network = await ethers.provider.getNetwork();
	console.log(`${acc1} balance `, await signer.getBalance().then(formatEther), `network`, network)
	return {signer, account: acc1}
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
export const DEPLOY_CARD_INFO = `./artifacts/deploy-card.json.txt`;
export async function deployCardContracts() {
	const shop = await deploy("CardShop", []) as CardShop;
	const name = "Cards Test", symbol = "cards"
	const inst = await deploy("Cards", [name, symbol, ""]) as Cards;
	const template = await deploy("CardTemplate", []) as CardTemplate;
	const tracker = await deploy("CardTracker", [inst.address]) as CardTracker;
	await shop.initialize(template.address, inst.address, tracker.address).then(waitTx)
	const deployInfo = {
		shop: shop.address,
		cards: inst.address,
		template: template.address,
		tracker: tracker.address,
	}
	await fs.writeFileSync(DEPLOY_CARD_INFO, JSON.stringify(deployInfo, null, 4))
	return {shop, template, inst, tracker}
}