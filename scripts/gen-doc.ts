import {docgen} from 'solidity-docgen';

async function main() {
	let config = {}
	let solcOutput = ''
	await docgen([{output: solcOutput}], config);
}

main().then()
