import {ethers, upgrades} from "hardhat";
import {attach, deploy, getDealine, tokensNet71, waitTx} from "./lib";
import {IERC20, ISwap, TokenRouter} from "../typechain";
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
		acc1,getDealine()).then(tx=>tx.wait())
	console.log(`ok, swap tx ${receipt.transactionHash}`)
}
async function test(tokens: any) {
	const baseToken = tokens.usdt;
	// const myRouter = await deploy("TokenRouter", []) as TokenRouter;
	// await myRouter.initTokenRouter(baseToken).then(waitTx);
	const myRouter = await ethers.getContractAt("TokenRouter", "0x3911ee3f9ac36aff117b3cce48b1098cfd93d792") as TokenRouter;
	const testApp = '0x16db1dc04e599f7a7c91de110d06c32fde9ae068';
	const swapRouter = tokens.__router //
	const path = [
		tokens.btc, tokens.usdt
	]
	const base20 = await ethers.getContractAt("IERC20", baseToken) as IERC20;
	const swap = await ethers.getContractAt("ISwap", swapRouter) as ISwap;
	// const useToken = await ethers.getContractAt("IERC20", path[0]) as IERC20;
	// await useToken.approve(myRouter.address, parseEther("1")).then(tx=>tx.wait());
	// console.log(`approved`)
	// await myRouter.depositWithSwap(swapRouter, parseEther("1"), 0, path, testApp, getDealine()).then(tx=>tx.wait())
	// console.log(`depositWithSwap ok`)
	//
	// await base20.approve(myRouter.address, parseEther("1")).then(waitTx)
	// await myRouter.depositBaseToken(parseEther("1"), testApp).then(waitTx)
	// console.log(`depositBaseToken. done`)
	//
	// await myRouter.withdraw(swapRouter, parseEther("0.1"), 0, [baseToken, tokens.btc], testApp, getDealine()).then(waitTx)
	// console.log(`withdraw with swap done`)
	// await myRouter.withdraw(swapRouter, 1, 0, [baseToken], testApp, getDealine()).then(waitTx)
	// console.log(`withdrawBaseToken done`)

	// query price of usdt
	const priceInCfx = await swap.getAmountsIn(parseEther("0.001"), [tokens.wcfx, tokens.usdt]).then(arr=>arr.map(formatEther))
	console.log(`get amounts in `, priceInCfx)
	// deposit native value
	await myRouter.depositNativeValue(swapRouter, parseEther("0.001"),
		[tokens.wcfx, tokens.usdt], testApp, getDealine(), {value: parseEther(priceInCfx[0])}).then(waitTx)
	console.log(`base token held by token router after depositing native value`,
		await base20.balanceOf(myRouter.address).then(formatEther))
}

main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
