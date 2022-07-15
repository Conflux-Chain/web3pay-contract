// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import {ethers, upgrades} from "hardhat";
import {APICoin, Controller, ERC1967Proxy, UpgradeableBeacon} from "../typechain";
const {parseEther, formatEther} = ethers.utils
async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  const [signer] = await ethers.getSigners()
  const acc1 = signer.address
  console.log(`${acc1} balance `, await signer.getBalance().then(formatEther), `network`, await ethers.provider.getNetwork())

  const today = new Date()
  const dateStr = [today.getDate(), today.getHours(), today.getMinutes(), today.getSeconds()].map(n=>n.toString().padStart(2, '0')).join('')

  const apiImpl = await deploy("APICoin", []) as APICoin
  const tmpApiProxy = await attach("APICoin", ethers.constants.AddressZero) as APICoin
  const initReq = await tmpApiProxy.populateTransaction.initialize(`API ${dateStr}`, `API${dateStr}`, []);
  // console.log(`constructor data`, initReq.data)

  const apiProxy = await deploy("ERC1967Proxy", [apiImpl.address, initReq.data]) as ERC1967Proxy
  const api = await attach("APICoin", apiProxy.address) as APICoin

  const controller = await deploy("Controller", [api!.address]) as Controller;
  await controller.createApp(`TestApp ${dateStr}`, `T${dateStr}`).then(tx=>tx.wait())
  console.log(`create new app ${await controller.appMapping(0)}`)
  //
  let appBase = await controller.appBase();
  const appImpl = await attach("UpgradeableBeacon", appBase) as UpgradeableBeacon
  console.log(`app base(UpgradeableBeacon) at ${appBase}`)
  console.log(`app impl at ${await appImpl.implementation()}`)
}
async function attach(name:string, to:string) {
  const template = await ethers.getContractFactory(name);
  return template.attach(to)
}
async function deployProxy(name: string, args: any[]) {
  const template = await ethers.getContractFactory(name);
  const proxy = await upgrades.deployProxy(template, args);
  const contract = await proxy.deployed();
  console.log(`deploy proxy ${name}, got ${contract.address}`);
  return contract;
}
async function deploy(name:string, args:any[]) {
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

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
