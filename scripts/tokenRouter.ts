import {ethers, upgrades} from "hardhat";
import {attach, deploy, getDealine, waitTx} from "./lib";
import {IERC20, ISwap, TokenRouter} from "../typechain";
import {formatEther, parseEther} from "ethers/lib/utils";
let acc1 = ''
async function main() {
	const [signer] = await ethers.getSigners()
	acc1 = signer.address;
	console.log(`${acc1} balance `, await signer.getBalance().then(formatEther), `network`, await ethers.provider.getNetwork())

	const tokens = {
		usdt: "0x7d682e65efc5c13bf4e394b8f376c48e6bae0355", // net71 faucet usdt,
		ppi: "0x49916ba65d0048c4bbb0a786a527d98d10a1cd2d", // ppi
		btc: "0x54593e02c39aeff52b166bd036797d2b1478de8d", // fauct btc
		__router: "0x873789aaf553fd0b4252d0d2b72c6331c47aff2e", // swappi router
	}
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
	// const myRouter = await deploy("TokenRouter", [baseToken]) as TokenRouter;
	const myRouter = await ethers.getContractAt("TokenRouter", "0x8948152d858d6713D0A62649DAD9B3384bdd92f3") as TokenRouter;
	const swapRouter = tokens.__router //
	const path = [
		tokens.btc, tokens.usdt
	]
	const useToken = await ethers.getContractAt("IERC20", path[0]) as IERC20;
	await useToken.approve(myRouter.address, parseEther("1")).then(tx=>tx.wait());
	console.log(`approved`)
	await myRouter.depositWithSwap(swapRouter, parseEther("1"), 0, path, myRouter.address, getDealine()).then(tx=>tx.wait())
	console.log(`depositWithSwap ok`)

	const base20 = await ethers.getContractAt("IERC20", baseToken) as IERC20;
	await base20.approve(myRouter.address, parseEther("1")).then(waitTx)
	await myRouter.depositBaseToken(parseEther("1"), ethers.constants.AddressZero).then(waitTx)
	console.log(`depositBaseToken. done`)

	await myRouter.withdraw(swapRouter, parseEther("0.1"), 0, [baseToken, tokens.btc], acc1, getDealine()).then(waitTx)
	console.log(`withdraw with swap done`)
	await myRouter.withdraw(swapRouter, 1, 0, [baseToken], acc1, getDealine()).then(waitTx)
	console.log(`withdrawBaseToken done`)
}

main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
