/**
 * Cross space, from core space call to evm space.
 */
import {address, Conflux, Drip, format} from "js-conflux-sdk"
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
	const {address: acc1} = cfx.wallet.addPrivateKey(pk)
	await claimToken(cfx, acc1, undefined, '');
	// await claimCfx(cfx, acc1);
	// await run(cfx, acc1);
}
async function run(cfx:Conflux, acc1:string) {
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

function buildFaucetContract(cfx: Conflux) {
	const abi = [
		{"inputs": [], "name": "claimCfx", "outputs": [], "stateMutability": "nonpayable", "type": "function"},
		{
			"inputs": [{"internalType": "address", "name": "tokenContractAddress", "type": "address"}],
			"name": "claimToken",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
	]
	const faucet = cfx.Contract({abi, address: 'cfxtest:acejjfa80vj06j2jgtz9pngkv423fhkuxj786kjr61'})
	return faucet;
}

export async function claimCfx(cfx: Conflux, account: string) {
	console.log(`claimCfx`)
	const faucet = buildFaucetContract(cfx);
	return faucet.claimCfx().sendTransaction({
		from: account,
	// @ts-ignore
	}).executed().then(res => res.transactionHash).then(hash => {
		console.log(`claim cfx ${hash}`)
	})
}
export async function claimToken(cfx: Conflux, account: string, token = "cfxtest:acepe88unk7fvs18436178up33hb4zkuf62a9dk1gv", to ='') {
	console.log(`claimToken, account ${account}`)
	console.log(`token ${token} to ${to}`)
	const faucet = buildFaucetContract(cfx);
	return faucet.claimToken(token).sendTransaction({
		from: account
	// @ts-ignore
	}).executed().then(res=>res.transactionHash).then(hash=>{
		console.log(`claim token ${hash}`)
	}).then(()=> {
		if (to) {
			const abi = [{
				"inputs": [
					{
						"internalType": "address",
						"name": "to",
						"type": "address"
					},
					{
						"internalType": "uint256",
						"name": "amount",
						"type": "uint256"
					}
				],
				"name": "transfer",
				"outputs": [
					{
						"internalType": "bool",
						"name": "",
						"type": "bool"
					}
				],
				"stateMutability": "nonpayable",
				"type": "function"
			},]
			const c20 = cfx.Contract({address: token, abi})
			return c20.transfer(to, parseEther("100")).sendTransaction({
				from: account
				// @ts-ignore
			}).executed();
		}
	});
}
if (module == require.main) {
	main().then()
}