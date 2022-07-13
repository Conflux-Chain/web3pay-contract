/**
 * OpenZeppelin ERC777 has `private` name and symbol fields, which doesn't match the requirement when
 * we want to setup them after constructing the contract.
 * Use this tool to change the modifier in the source file under node_modules/@openzeppelin/contracts.
 */
import * as fs from "fs";

async function modifyFieldModifier() {
	const path = './node_modules/@openzeppelin/contracts/token/ERC777/ERC777.sol'
	const content = fs.readFileSync(path).toString()
	const replaced = content
		.replace("string private _name", "string internal _name")
		.replace("string private _symbol", "string internal _symbol")
	fs.writeFileSync(path, replaced)
}
async function main() {
	await modifyFieldModifier()
}

if (module === require.main) {
	main().then()
}