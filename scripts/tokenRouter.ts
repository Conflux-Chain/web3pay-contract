import {ethers, upgrades} from "hardhat";
import {attach, deploy, getDeadline, tokensNet71, waitTx} from "./lib";
import {APPCoin, IERC20, ISwap, TokenRouter} from "../typechain";
import {formatEther, parseEther} from "ethers/lib/utils";
let acc1 = ''
async function main() {
	const [signer] = await ethers.getSigners()
	acc1 = signer.address;
	console.log(`${acc1} balance `, await signer.getBalance().then(formatEther), `network`, await ethers.provider.getNetwork())

	const tokens = tokensNet71;
	// await swap(tokens, 'btc', 'ppi', "100");
	// await swap(tokens, 'btc', 'usdt', "100");
	await test(tokens);
}
async function swap(tokens: any, input:string, output:string, amountUnit: string) {
	const swap = await ethers.getContractAt("ISwap", tokens.__router) as ISwap;
	const erc20 = await ethers.getContractAt("IERC20", tokens[input]) as IERC20;
	console.log(`balance of ${input} ${await erc20.balanceOf(acc1).then(formatEther)}`)
	await erc20.approve(tokens.__router, parseEther(amountUnit)).then(waitTx)
	const receipt = await swap.swapExactTokensForTokens(parseEther(amountUnit), 0,
		[tokens[input], tokens[output]],
		acc1,getDeadline()).then(tx=>tx.wait())
	console.log(`ok, swap tx ${receipt.transactionHash}`)
}
async function test(tokens: any) {
	// controller 0x0CCe3a75536C3Ba9612BD0eef2979cb494562340
	const baseToken = tokens.usdt;
	// const myRouter = await deploy("TokenRouter", []) as TokenRouter;
	// await myRouter.initTokenRouter(baseToken).then(waitTx);
	const myRouter = await ethers.getContractAt("TokenRouter", "0xc1bedb2d272272f367ca9f083043278cade7c179") as TokenRouter;
	const testApp = '0x04599b35466F23cDf7e28762E5216C6d5B4edDE5';
	const swapRouter = tokens.__router //
	const path = [
		tokens.btc, baseToken,
	]
	const base20 = await ethers.getContractAt("IERC20", baseToken) as IERC20;
	const swap = await ethers.getContractAt("ISwap", swapRouter) as ISwap;
	// await depositTokens(swap, tokens, myRouter, path, testApp, base20);
	// await withdraw(swap, tokens, myRouter, baseToken, testApp, base20);
	await depositNative(swap, tokens, myRouter, swapRouter, testApp, base20);
}
async function depositTokens(swap:ISwap, tokens:any, myRouter:TokenRouter, path:string[], testApp: string, base20: IERC20) {
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
}
async function withdraw(swap:ISwap, tokens:any, myRouter:TokenRouter, baseToken:string, testApp: string, base20: IERC20) {
	const dApp = await attach("APPCoin", testApp) as APPCoin;
	if (await dApp.frozenMap(acc1).then(flag=>flag.eq(0))) {
		await dApp.withdrawRequest().then(waitTx);
		console.log(`withdrawRequest sent`)
	}
	if (await dApp.forceWithdrawDelay().then(delay=>delay.gt(0))){
		await dApp.setForceWithdrawDelay(0).then(waitTx)
		console.log(`set forceWithdrawDelay to 0`)
	}
	await dApp.forceWithdraw().then(waitTx)
	console.log(`forceWithdraw done.`)

	const swapRouter = tokens.__router //
	await myRouter.withdraw(swapRouter, parseEther("0.1"), 0, [baseToken, tokens.btc], testApp, getDeadline()).then(waitTx)
	console.log(`withdraw with swap done`)
	await myRouter.withdraw(swapRouter, 1, 0, [baseToken], testApp, getDeadline()).then(waitTx)
	console.log(`withdrawBaseToken done`)
}
async function depositNative(swap:ISwap, tokens:any, myRouter:TokenRouter, swapRouter:string, testApp: string, base20: IERC20) {
	// query price of usdt
	// const priceInCfx = await swap.getAmountsIn(parseEther("0.001"), [tokens.wcfx, tokens.usdt]).then(arr=>arr.map(formatEther))
	// let costCfx = priceInCfx[0];
	let costCfx = "1"
	// console.log(`get amounts in `, priceInCfx)
	// deposit native value
	await myRouter.depositNativeValue(swapRouter, parseEther("0.001"),
		[tokens.wcfx, tokens.usdt], testApp, getDeadline(), {value: parseEther(costCfx)}).then(waitTx)
	console.log(`base token held by token router after depositing native value`,
		await base20.balanceOf(myRouter.address).then(formatEther))
}

main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
