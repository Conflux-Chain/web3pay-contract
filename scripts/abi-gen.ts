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
	const version = "/v2"
	let saveAtDir = `./abi${version}`
	if (!fs.existsSync(saveAtDir)) {
		fs.mkdirSync(saveAtDir)
	}
	let path = `./artifacts/contracts${version}`;
	const files = fs.readdirSync(path)
	console.log(`found ${files.length} file(s) at ${path}`)
	for (let dir of files) {
		const name = dir.split('.')[0]
		let jsonPath = `.${path}/${dir}/${name}.json`;
		if (!fs.existsSync(jsonPath)) {
			continue
		}
		const json = require(jsonPath);
		await fs.writeFileSync(`${saveAtDir}/${name}.abi`, JSON.stringify(json.abi, null, 4))
		await fs.writeFileSync(`${saveAtDir}/${name}.json`, JSON.stringify({abi: json.abi}, null, 4))
		console.log(`generate for ${name}`)
	}
	console.log(`done.`)
}

if (module === require.main) {
	main().then()
}