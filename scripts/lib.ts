import {ethers} from "hardhat";
export const tokensNet71 = {
	usdt: "0x7d682e65efc5c13bf4e394b8f376c48e6bae0355", // net71 faucet usdt,
	ppi: "0x49916ba65d0048c4bbb0a786a527d98d10a1cd2d", // ppi
	btc: "0x54593e02c39aeff52b166bd036797d2b1478de8d", // fauct btc
	wcfx: "0x2ed3dddae5b2f321af0806181fbfa6d049be47d8",
	testApp: "0x04599b35466F23cDf7e28762E5216C6d5B4edDE5",
	__router: "0x873789aaf553fd0b4252d0d2b72c6331c47aff2e", // swappi router
}
export async function attach(name:string, to:string) {
	const template = await ethers.getContractFactory(name);
	return template.attach(to)
}
export function getDeadline(diff: number = 1000) {
	return Math.round(Date.now()/1000 ) + diff
}
export function waitTx(tx:any) {
	return tx.wait();
}
export async function sleep(ms:number) {
	return new Promise(r=>setTimeout(r, ms))
}
export async function deploy(name:string, args:any[]) {
	// We get the contract to deploy
	const Factory = await ethers.getContractFactory(name).catch(err=>{
		console.log(`error`, err)
	});
	if (!Factory) {
		return;
	}
	const deployer = await Factory.deploy(...args,
	).catch(err=>{
		console.log(`error deploy.`, err)
	});
	if (!deployer) {
		return;
	}
	const instance = await deployer.deployed();

	console.log(name+" deployed to:", deployer.address);
	return instance;
}