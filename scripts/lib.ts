import {ethers} from "hardhat";

export async function attach(name:string, to:string) {
	const template = await ethers.getContractFactory(name);
	return template.attach(to)
}
export function getDealine(diff: number = 1000) {
	return Math.round(Date.now()/1000 ) + diff
}
export function waitTx(tx:any) {
	return tx.wait();
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