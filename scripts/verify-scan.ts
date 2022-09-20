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
	await Promise.all([
		// verifyContract('Controller', '0x0cce3a75536c3ba9612bd0eef2979cb494562340'),
		// verifyContract('APICoin', '0x1332DC018a7bA4b63B766f6aa674C12Ea09a9211'), // api impl
		verifyContract('Airdrop', '0xc9d25A0f060e69A57fbC86144181d7520A12100E'),
		// verifyContract('TokenRouter', '0x8948152d858d6713D0A62649DAD9B3384bdd92f3'),
		]
	)
}
export async function verifyContract(contract: string, address: string) {
	console.log(`verify for ${contract} at ${address}`)
	let result = await verifyAsync(host, address, contract);
	let resultJson = JSON.parse(result)
	fs.writeFileSync(`./artifacts/verify_${contract}.txt`,
		JSON.stringify(resultJson, null, 4))
	delete resultJson["sourceCode"]
	delete resultJson["abi"]
	const {exactMatch, errors} = resultJson;
	console.log(`result ${contract} , exactMatch `,exactMatch,` errors [${(errors||[]).join(',')}]`, )
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
			'Content-Length': data.length
		}
	}

	const req = https.request(options, (res: IncomingMessage) => {
		console.log(`status code: ${res.statusCode}`)

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