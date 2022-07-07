/**
 * Use this tool to generate :
 * 1. pure abi files, the resources for generating golang source files.
 * 2. json abi files, used by frontend.
 *
 * Results are saved at ../abi.
 */
import * as fs from "fs";

export async function gen(dir:string) {

}
export async function main() {
	let saveAtDir = './abi'
	let path = './artifacts/contracts';
	const files = fs.readdirSync(path)
	console.log(`found ${files.length} file(s) at ${path}`)
	for (let dir of files) {
		const name = dir.split('.')[0]
		const json = require(`.${path}/${dir}/${name}.json`)
		await fs.writeFileSync(`${saveAtDir}/${name}.abi`, JSON.stringify(json.abi, null, 4))
		await fs.writeFileSync(`${saveAtDir}/${name}.json`, JSON.stringify({abi: json.abi}, null, 4))
		console.log(`generate for ${name}`)
	}
	console.log(`done.`)
}

if (module === require.main) {
	main().then()
}