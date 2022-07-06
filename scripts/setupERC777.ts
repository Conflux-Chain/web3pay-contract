/**
 * OpenZeppelin ERC777 has `private` name and symbol fields, which doesn't match the requirement when
 * we want setup them after construction of then contract.
 * Use this tool to modify the modifier in the source file under node_modules/@openzeppelin/contracts
 */
import * as fs from "fs";

async function modifyFieldModifier() {
	const path = '../node_modules/@openzeppelin/contracts/token/ERC777/ERC777.sol'
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