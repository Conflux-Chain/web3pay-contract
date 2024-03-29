// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import {ethers, upgrades} from "hardhat";
import {
  Airdrop,
  APICoin,
  Controller,
  ERC1967Proxy,
  IERC20,
  ISwap,
  TokenRouter,
  UpgradeableBeacon
} from "../typechain";
const {parseEther, formatEther} = ethers.utils
import {verifyContract} from "./verify-scan";
import {
  approveERC20,
  attach,
  deploy,
  depositTokens,
  getDeadline,
  mintERC20,
  networkInfo,
  sleep,
  tokensNet71, waitTx
} from "./lib";
import {ContractTransaction} from "ethers";
import * as fs from "fs";

let deployInfoFile = `./artifacts/deployInfo.json.txt`;

async function main() {
  // await upgradeApp()
  // await deployIt()
  await depositForLatestApp()
}

function loadDeployInfo() {
  const deployInfoStr = fs.readFileSync(deployInfoFile).toString();
  const deployInfo = JSON.parse(deployInfoStr)
  return deployInfo;
}
async function depositForLatestApp() {
  const deployInfo = loadDeployInfo();
  let controllerAddr = deployInfo['controllerProxy'];
  console.log(`user controller ${controllerAddr}`)
  const controller = await attach("Controller", controllerAddr) as Controller;
  const [apps, total] = await controller.listApp(0, 1_000)
  const latest = apps[total.toNumber() - 1]
  console.log(`deposit to app ${latest}`)
  await deposit(latest);
}
async function deposit(newApp: string) {
  const  {signer, account:acc1} = await networkInfo()
  const tokens = tokensNet71;

  const app = await attach("Airdrop", newApp) as Airdrop
  const apiAddr = await app.apiCoin()
  const api = await attach("APICoin", apiAddr) as APICoin;
  const baseToken = await api.baseToken()
  const path = [
    tokens.btc, baseToken,
  ]
  const base20 = await ethers.getContractAt("IERC20", baseToken) as IERC20;
  await depositTokens(tokens, api, path, newApp, base20);
}

async function deployIt() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  await networkInfo()
  let tokens = tokensNet71;
  let baseToken = tokens.usdt;

  const today = new Date()
  const dateStr = [today.getDate(), today.getHours(), today.getMinutes(), today.getSeconds()].map(n=>n.toString().padStart(2, '0')).join('')

  const apiImpl = await deploy("APICoin", []) as APICoin
  const tmpApiProxy = await attach("APICoin", ethers.constants.AddressZero) as APICoin
  const initReq = await tmpApiProxy.populateTransaction.initialize(`API ${dateStr}`, `API${dateStr}`, baseToken, []);
  // console.log(`constructor data`, initReq.data)

  const apiProxy = await deploy("ERC1967Proxy", [apiImpl.address, initReq.data]) as ERC1967Proxy
  const api = await attach("APICoin", apiProxy.address) as APICoin

  const appImpl = await deploy("Airdrop", []) as Airdrop;
  const appBase = await deploy("UpgradeableBeacon", [appImpl.address]) as UpgradeableBeacon;

  const controllerImpl = await deploy("Controller", []) as Controller;
  const tmpController = await attach("Controller", ethers.constants.AddressZero) as Controller;
  const cInitReq = await tmpController.populateTransaction.initialize(api!.address, appBase!.address);
  const cProxy = await deploy("ERC1967Proxy", [controllerImpl.address, cInitReq.data]) as ERC1967Proxy
  const controller = await attach("Controller", cProxy.address) as Controller;

  await controller.createApp(`TestApp ${dateStr}`, `T${dateStr}`, "https://test.app.com",
      ethers.utils.parseEther("0.003"))
      .then(tx=>tx.wait())
  let newApp = await controller.appMapping(0);
  console.log(`create new app ${newApp}`)

  // let appBase = await controller.appBase();
  const appBeacon = await attach("UpgradeableBeacon", appBase!.address) as UpgradeableBeacon
  console.log(`app base(UpgradeableBeacon) at ${appBase.address}`)
  let appImplStub = await appBeacon.implementation();
  console.log(`app impl at ${appImplStub}`)
  const deployInfo = {
    apiImpl: apiImpl.address, apiProxy: api.address,
    appImpl: apiImpl.address, appBeaconBase: appBase.address,
    controllerImpl: controllerImpl.address, controllerProxy: controller.address,
  }
  await fs.writeFileSync(deployInfoFile, JSON.stringify(deployInfo, null, 4))
  console.log(`wait before verifying...`)
  await sleep(10_000)
  await verifyContract("APICoin", apiImpl.address).catch(err=>console.log(`verify contract fail ${err}`))
  await verifyContract("Controller", controllerImpl.address).catch(err=>console.log(`verify contract fail ${err}`))
  await verifyContract("Airdrop", appImplStub).catch(err=>console.log(`verify contract fail ${err}`))
}
async function deployProxy(name: string, args: any[]) {
  const template = await ethers.getContractFactory(name);
  const proxy = await upgrades.deployProxy(template, args);
  const contract = await proxy.deployed();
  console.log(`deploy proxy ${name}, got ${contract.address}`);
  return contract;
}

async function upgradeApi() {
  const deployInfo = loadDeployInfo();
  const apiProxy = deployInfo.apiProxy;
  console.log(`use api proxy ${apiProxy}`)
  const api = await attach("APICoin", apiProxy) as APICoin;
  const apiv2 = await deploy("APICoin",[]) as APICoin;
  await api.upgradeTo(apiv2.address).then(waitTx)
  console.log(`api upgraded`)
}
async function upgradeApp() {
  console.log(`upgradeApp`)
  const deployInfo = loadDeployInfo();
  const newAppImpl = await deploy("Airdrop", [])
  const beacon = await attach("UpgradeableBeacon", deployInfo['appBeaconBase']) as UpgradeableBeacon
  const receipt = await beacon.upgradeTo(newAppImpl?.address!).then(tx=>tx.wait())
  console.log(`upgraded to ${newAppImpl?.address} , tx ${receipt.transactionHash}`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
