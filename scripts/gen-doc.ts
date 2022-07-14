// @ts-ignore
import {docgen} from 'solidity-docgen';
// Should run it through the `doc` task in package.json
async function main() {
	let config = {}
	let solcOutput = ''
	await docgen([{output: solcOutput}], config);
}

main().then()
