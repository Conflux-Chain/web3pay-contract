/**
 * Cross space, from core space call to evm space.
 */
import {Conflux, Drip, format} from "js-conflux-sdk"
const addressUtil = require('js-conflux-sdk/src/util/address');
import {getDeadline, tokensNet71} from "./lib";
import {ethers} from "hardhat";
import {formatEther, parseEther} from "ethers/lib/utils";
import * as dotenv from "dotenv";
import {ISwap} from "../typechain";
const {abi: apiAbi} = require("../artifacts/contracts/APICoin.sol/APICoin.json")
dotenv.config();
async function main() {
	const pk = process.env.PRIVATE_KEY
	//
	let url = `https://test.confluxrpc.com`
	const cfx = new Conflux({url})
	await cfx.updateNetworkId();
	const {address:acc1} = cfx.wallet.addPrivateKey(pk)
	const mappedAddr = addressUtil.cfxMappedEVMSpaceAddress(acc1)
	const balance = await cfx.getBalance(acc1).then(res=>new Drip(res).toCFX())
	console.log(`network ${await cfx.getStatus().then(res=>res.networkId)} account ${acc1} balance ${balance} CFX`)
	console.log(`hex address ${format.hexAddress(acc1)} mapped address ${mappedAddr}`)

	const crossCall = cfx.InternalContract("CrossSpaceCall")
	// function callEVM(bytes20 to, bytes calldata data) external payable returns (bytes memory output);
	const {__router, usdt, btc, wcfx, testApp} = tokensNet71;
	const api = await ethers.getContractAt("APICoin", ethers.constants.AddressZero);
	const swap = await ethers.getContractAt("ISwap", __router) as ISwap;
	const {data:estimateCfxCostReq} = await swap.populateTransaction.getAmountsIn(parseEther("0.003"), [wcfx, usdt])
	const result = await crossCall.staticCallEVM(__router, estimateCfxCostReq)
	const decoded = ethers.utils.defaultAbiCoder.decode(['uint256[]'], result)[0].map(formatEther)
	console.log(`staticCallEVM , cost cfx `, decoded)
	// function depositNativeValue(address swap, uint amountOut, address[] calldata path, address toApp, uint deadline) public payable {
	const {data} = await api.populateTransaction.depositNativeValue(__router, parseEther("0.003"), [wcfx, usdt], testApp, getDeadline())
	const {transactionHash} = await crossCall.callEVM('0xc1bedb2d272272f367ca9f083043278cade7c179', data).sendTransaction({
		from: acc1,
		// value: parseEther(decoded[0])
		value: parseEther("1")
	}).executed();
	console.log(`depositNativeValue done.`, transactionHash)
}

if (module == require.main) {
	main().then()
}