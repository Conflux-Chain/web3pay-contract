if (!process.env.TEST_SCAN_URL) {
	require("dotenv").config()
}
const [schema, host] = process.env.TEST_SCAN_URL!.split("://")
let https = schema === 'http' ?
	require('http') : require('https')
let port = schema === 'http' ? 80 : 443
import * as fs from "fs";
import {IncomingMessage} from "http";
async function main() {
	// Verify the upgraded App implementation. Address is overridable via APP_IMPL
	// (default points at the testnet impl 0x11ef6d33004FFCee427783dd9A73e208B87c90AA).
	// Requires ./flatten/App.txt to exist (generate with: hardhat flatten contracts/v2/App.sol > flatten/App.txt)
	// and TEST_SCAN_URL to be set (e.g. https://evmtestnet.confluxscan.io/api).
	const addr = process.env.APP_IMPL || "0x11ef6d33004FFCee427783dd9A73e208B87c90AA";
	await verifyContract('App', addr);
}
export async function verifyContract(contract: string, address: string) {
	console.log(`verify for ${contract} at ${address}`)
	let result = await verifyAsync(host, address, contract);
	let resultJson = JSON.parse(result)
	fs.writeFileSync(`./artifacts/verify_${contract}.txt`,
		JSON.stringify(resultJson, null, 4))
	delete resultJson["sourceCode"]
	delete resultJson["abi"]
	const {exactMatch, errors, result: {errors: resultErrors}} = resultJson;
	console.log(`result ${contract} , exactMatch `,exactMatch,` errors [${(errors||resultErrors||[]).join(',')}]`, )
}
async function verifyAsync(host:string, address:string, contract:string) {
	return new Promise<string>(resolve => verify(host, address, contract, resolve))
}
function verify(host:string, address:string, contract:string, fn:(str:string)=>void) {

	const source = fs.readFileSync(`./flatten/${contract}.txt`).toString()

	const body = {
		"address": address,
		"name": contract,
		"sourceCode": source,
		"compiler": "0.8.4",
		"license": "None",
		"optimizeRuns": 1
	}

	const data = JSON.stringify(body)
	const options = {
		hostname: host,
		port,
		path: '/v1/contract/verify',
		method: 'POST',
		headers: {
			'Content-Type': 'application/json',
			'Accept': 'application/json',
		}
	}

	const req = https.request(options, (res: IncomingMessage) => {
		console.log(`status code: ${res.statusCode} ${contract}`)
		if (res.statusCode == 400) {
			console.log(`request data length ${data.length}, source code length ${source.length}, ${contract}`)
		}
		const array:string[] = []
		res.on('data', (d: string | Uint8Array) => {
			array.push(d.toString())
		})
		res.on("end", ()=>{
			fn(array.join(""))
		})
	})

	req.on('error', (error: any) => {
		console.error('verify error.', error)
	})

	req.write(data)
	req.end()
}
if (module === require.main) {
	main().then()
}