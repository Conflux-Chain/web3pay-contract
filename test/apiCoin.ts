import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import {APICoin, APPCoin, Controller} from "../typechain";
import { ContractReceipt } from "ethers";
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";
const {
  utils: { formatEther, parseEther },
} = ethers;
async function attach(name:string, to:string) {
  const template = await ethers.getContractFactory(name);
  return template.attach(to)
}
async function deploy(name:string,args: any[]) {
  const template = await ethers.getContractFactory(name);
  const deploy = await template.deploy(args)
  const instance = await deploy.deployed();
  console.log(`deploy ${name} at ${instance.address}, tx ${deploy.deployTransaction.hash}`)
  return instance;
}
async function deployApp(name: string, args: any[]) {
  const app = await deploy(name, []).then(res=>res as APPCoin)
  const [apiCoin,appOwner,name_,symbol] = args;
  await app.init(apiCoin,appOwner,name_,symbol)
  return app;
}
async function deployProxy(name: string, args: any[]) {
  const template = await ethers.getContractFactory(name);
  const proxy = await upgrades.deployProxy(template, args);
  const contract = await proxy.deployed();
  console.log(`deploy proxy ${name}, got ${contract.address}`);
  return contract;
}
function dumpEvent(receipt: ContractReceipt) {
  console.log(
    receipt.events?.map((e) => `${e.address} ${e.event}, ${e.args}`).join("\n")
  );
  return receipt;
}
async function deployAndDeposit(signer2:SignerWithAddress) {
  const acc2 = await signer2.getAddress();
  const api = (await deployProxy("APICoin", [])) as APICoin;
  const app = (await deployApp("APPCoin", [
    api.address,
    acc2, // set acc2 as app owner
    "APP 1",
    "APP1",
  ])) as APPCoin;
  await api
      .depositToApp(app.address, { value: parseEther("1") })
      .then((res) => res.wait());
  const app2 = await app.connect(signer2);
  return {api, app, app2}
}
describe("Controller", async function () {
  const signerArr = await ethers.getSigners();
  const [signer1, signer2, signer3] = signerArr;
  const [acc1, acc2] = await Promise.all(signerArr.map((s) => s.getAddress()));
  it("createApp" , async function (){
    const controller = await deploy("Controller", []).then(res=>res as Controller);
    console.log(``)
    const tx = await controller.createApp("CoinA", "CA").then(res=>res.wait())
    expect(tx).emit(controller, controller.interface.events["APP_CREATED(address,address)"].name);
    // @ts-ignore
    const createdAppAddr = tx.events?.filter(e=>e.event === controller.interface.events["APP_CREATED(address,address)"].name)
        [0].args[0]
    //
    const app = await attach("APPCoin", createdAppAddr).then(res=>res as APPCoin)
    const api = await controller.apiProxy().then(res=>attach("APICoin", res)).then(res=>res as APICoin)
    console.log(`app business owner`, await app.appOwner())
    console.log(`app contract owner`, await app.owner())

    console.log(`api contract owner`, await api.owner())
    expect(await app.appOwner()).eq(acc1)
    expect(await app.owner()).eq(acc1)
    expect(await api.owner()).eq(acc1)
    expect(await app.name()).eq("CoinA")
    expect(await app.symbol()).eq("CA")
  })
})
describe("ApiCoin", async function () {
  const signerArr = await ethers.getSigners();
  const [signer1, signer2, signer3] = signerArr;
  const [acc1, acc2] = await Promise.all(signerArr.map((s) => s.getAddress()));
  it("Should deposit to app", async function () {
    const api = (await deployProxy("APICoin", [])) as APICoin;
    const app = (await deployApp("APPCoin", [
      api.address,
      acc1,
      "APP 1",
      "APP1",
    ])) as APPCoin;

    expect(await app.apiCoin()).to.equal(api.address);
    //
    const spend = parseEther("1.23");
    const account = await api.signer.getAddress();
    expect(
      await api
        .depositToApp(app.address, { value: spend })
        .then((res) => res.wait())
        .then(dumpEvent)
    )
      .emit(app, app.interface.events["Transfer(address,address,uint256)"].name)
      .withArgs(ethers.constants.AddressZero, account, spend);
    await app.balanceOf(account).then((res) => {
      console.log(`balance of app, user ${account}`, formatEther(res));
    });
    //
  });
  it("set resource weights", async function () {
    const api = (await deployProxy("APICoin", [])) as APICoin;
    const app = (await deployApp("APPCoin", [
      api.address,
      acc1,
      "APP 1",
      "APP1",
    ])) as APPCoin;
    let index = 0;
    await app
      .setResourceWeight(index, "path1", 1)
      .then((res) => res.wait())
      .then(dumpEvent)
      .then((r) => {
        // console.log(JSON.stringify(r));
      });
    expect(
      await app.resourceWeights(index).then((res) => {
        // console.log(`weight info`, res);
        // eslint-disable-next-line no-unused-vars
        const [path, weight] = res;
        return weight;
      })
    ).to.be.eq(1);

    //
    expect(await app.nextWeightIndex()).to.be.eq(index + 1);

    index = 3;
    await expect(
      app.setResourceWeight(index, "pathN", 3).then((res) => res.wait())
    ).to.be.revertedWith(`invalid index`);
    // batch
    await app
      .setResourceWeightBatch([0, 1, 2], ["p0", "p1", "p2"], [10, 11, 12])
      .then((res) => res.wait());
    expect(await app.nextWeightIndex()).to.be.eq(3);
    //
    const list = await app.listResources(0, 3);
    expect(list.length).to.be.eq(3);
    const [[path, w]] = list;
    expect(path).eq("p0");
    expect(w).eq(10);
  });
  it("check permission", async function () {
    const api = (await deployProxy("APICoin", [])) as APICoin;
    const app = (await deployApp("APPCoin", [
      api.address,
      acc1,
      "APP 1",
      "APP1",
    ])) as APPCoin;
    await api
      .depositToApp(app.address, { value: parseEther("1") })
      .then((res) => res.wait());
    //
    const app2 = await app.connect(signer2);
    const app3 = await app.connect(signer3);
    console.log(`app contract owner   ${await app.owner()}`);
    console.log(`app business owner   ${await app.appOwner()}`);
    console.log(`app  signer          ${await app.signer.getAddress()}`);
    console.log(`app2 signer          ${await app2.signer.getAddress()}`);
    await expect(
      app3.freeze(api.address, true).then((res) => res.wait())
    ).to.be.revertedWith(`Unauthorised`);
    //
    await expect(
      app2.transfer(api.address, parseEther("1")).then((res) => res.wait())
    ).to.be.revertedWith(`Not permitted`);

    await expect(
      app2
        .send(api.address, parseEther("1"), Buffer.from(""))
        .then((res) => res.wait())
    ).to.be.revertedWith(`Not permitted`);

    await expect(
      app2.burn(parseEther("1"), Buffer.from("")).then((res) => res.wait())
    ).to.be.revertedWith(`Not permitted`);

    await expect(app2.setResourceWeight(0, "p0", 10)).to.be.revertedWith(
      `not app owner`
    );
    // app2
    //   .transfer(api.address, parseEther("2"))
    //   .then((res) => res.wait())
    //   .catch((err) => {
    //     console.log(`transfer fail:`, err);
    //   });
  });
  it("withdraw", async function () {
    const {api, app, app2} = await deployAndDeposit(signer2);
    // freeze acc1 by admin
    await app2.freeze(acc1, true).then((res) => res.wait());
    await expect(
      app.forceWithdraw().then((res) => res.wait())
    ).to.be.revertedWith(`Frozen by admin`);
    await expect(
      app.withdrawRequest().then((res) => res.wait())
    ).to.be.revertedWith(`Account is frozen`);
    // unfreeze
    await app2.freeze(acc1, false).then((res) => res.wait());
    await expect(
      app.forceWithdraw().then((res) => res.wait())
    ).to.be.revertedWith(`Withdraw request first`);
    expect(await app.withdrawRequest().then((res) => res.wait()))
      .to.be.emit(app, app.interface.events["Frozen(address)"].name)
      .withArgs(acc1);
    await expect(
      app.forceWithdraw().then((res) => res.wait())
    ).to.be.revertedWith(`Waiting time`);

    // should transfer api coin from App to acc1
    await app2.setForceWithdrawAfterBlock(0).then((res) => res.wait());
    expect(await app.forceWithdraw().then((res) => res.wait()))
      .emit(api, api.interface.events["Transfer(address,address,uint256)"].name)
      .withArgs(app.address, acc1, parseEther("1"));
    expect(await app.balanceOf(acc1)).eq(0);

  });
  it("charge and auto refund", async () => {
    const {api, app, app2} = await deployAndDeposit(signer1);
    // charge without refund
    await expect(app.charge(acc1, parseEther("0.1"), Buffer.from("扣费")))
        .to.be.emit(app, app.interface.events["Transfer(address,address,uint256)"].name)
        .withArgs(acc1, ethers.constants.AddressZero, parseEther("0.1"))
    await expect(app.withdrawRequest()).emit(app, app.interface.events["Frozen(address)"].name)
        .withArgs(acc1)
    await expect(app.charge(acc1, parseEther("0.1"), Buffer.from("扣费")))
        .to.be.emit(app, app.interface.events["Transfer(address,address,uint256)"].name)
        .withArgs(acc1, ethers.constants.AddressZero, parseEther("0.8"))// burn
        .emit(api, api.interface.events["Transfer(address,address,uint256)"].name)
        .withArgs(app.address, acc1, parseEther("0.8")) // refund api code
    expect(1).eq(1);
  });
});
