// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import {ethers, upgrades} from "hardhat";
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
  const api = await deployProxy("APICoin", [])
  await deploy("Controller", [api.address]);
  // await deploy("APPCoin", []);
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
  console.log(`--- 1`);
  const deployer = await Factory.deploy(...args,
      // {gasLimit: 7_327_272, gasPrice: 1_000_000_000}
  ).catch(err=>{
    console.log(`error deploy.`, err)
  });
  if (!deployer) {
    return;
  }
  console.log('---', deployer.deployTransaction.gasPrice);
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
