import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import {Airdrop, APICoin, ApiV2, APPCoin, AppV2, Controller, UpgradeableBeacon} from "../typechain";
import {ContractReceipt, ContractTransaction} from "ethers";
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";
import assert from "assert";

const {
  utils: { formatEther, parseEther },
} = ethers;
enum OP {ADD,UPDATE,DELETE,  NO_PENDING, PENDING_INIT_DEFAULT}
let baseToken = ethers.constants.AddressZero
async function attach(name:string, to:string) {
  const template = await ethers.getContractFactory(name);
  return template.attach(to)
}
async function deploy(name:string,args: any[]) {
  const template = await ethers.getContractFactory(name);
  const deploy = await template.deploy(...args)
  const instance = await deploy.deployed();
  console.log(`deploy ${name} at ${instance.address}, tx ${deploy.deployTransaction.hash}`)
  return instance;
}
async function deployApp(name: string, args: any[]) {
  const app = await deploy(name, []).then(res=>res as APPCoin)
  const [apiCoin,appOwner,name_,symbol, weight] = args;
  await app.init(apiCoin,appOwner,name_,symbol, "https://evm.confluxscan.net", weight)
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
async function deployAndDeposit(appOwner:SignerWithAddress, appTemplate="APPCoin") {
  const ownerAddr = await appOwner.getAddress();
  const api = (await deployProxy("APICoin", ["main coin", "mc", baseToken, []])) as APICoin;
  const appWithOwnerSet = (await deployApp(appTemplate, [
    api.address,
    ownerAddr, // set app owner
    "APP 1",
    "APP1", 1,
  ])).connect(appOwner) as APPCoin;
  await api
      .depositToApp(appWithOwnerSet.address, { value: parseEther("1") })
      .then((res) => res.wait());
  const appWithDefaultOwner = await appWithOwnerSet.connect(api.signer);
  return {api, app:appWithOwnerSet, app2:appWithDefaultOwner}
}
describe("Controller", async function () {
  const signerArr = await ethers.getSigners();
  const [signer1, signer2, signer3] = signerArr;
  const [acc1, acc2] = await Promise.all(signerArr.map((s) => s.getAddress()));
  it("createApp" , async function (){
    const api = await deployProxy("APICoin", ["main coin", "mc", baseToken, []]) as APICoin
    const app_ = await deploy("Airdrop", []) as Airdrop
    const appBeacon = await deploy("UpgradeableBeacon", [app_.address]) as UpgradeableBeacon;
    const controller = await deploy("Controller", [api.address, appBeacon.address]).then(res=>res as Controller);

    const tx = controller.createApp("CoinA", "CA", "app description", 1)
    await expect(tx).emit(controller, controller.interface.events["APP_CREATED(address,address)"].name);
    // @ts-ignore
    const createdAppAddr = (await (await tx).wait()).events?.filter(e=>e.event === controller.interface.events["APP_CREATED(address,address)"].name)
        [0].args[0]
    //
    const app = await attach("APPCoin", createdAppAddr).then(res=>res as APPCoin)
    console.log(`app business owner`, await app.appOwner())
    console.log(`app contract owner`, await app.owner())

    console.log(`api contract owner`, await api.owner())
    expect(await app.appOwner()).eq(acc1)
    expect(await app.owner()).eq(acc1)
    expect(await api.owner()).eq(acc1)
    expect(await app.name()).eq("CoinA")
    expect(await app.symbol()).eq("CA")
    // list created app
    controller.createApp("CoinB", "CB", "app description", 1).then(res=>res.wait())
    const [createdAppArr, total] = await controller.listAppByCreator(acc1, 0, 10)
    expect(createdAppArr.length).eq(2)
    expect(total).eq(2)
    expect(createdAppArr[0].addr).eq(createdAppAddr)
  })
  it("list created app", async function (){
    const app_ = await deploy("Airdrop", []) as Airdrop
    const appBeacon = await deploy("UpgradeableBeacon", [app_.address]) as UpgradeableBeacon;
    const controller = await deploy("Controller", [ethers.constants.AddressZero, appBeacon.address]).then(res=>res as Controller);
    await controller.createApp("app 1", "a1", "app description", 1).then(tx=>tx.wait());
    await controller.createApp("app 2", "a2", "app description", 2).then(tx=>tx.wait());
    const [arr, total] = await controller.listApp(0, 10);
    expect(arr.length).eq(2)
    expect(total).eq(2)
  })
  it("upgrade api contract, UUPS", async function (){
    const api = await deployProxy("APICoin", ["main coin", "mc", baseToken, []]) as APICoin
    const app_ = await deploy("Airdrop", []) as Airdrop
    const appBeacon = await deploy("UpgradeableBeacon", [app_.address]) as UpgradeableBeacon;
    const controller = await deploy("Controller", [api.address, appBeacon.address]).then(res=>res as Controller);
    await controller.createApp("app 1", "a1", "app description", 3).then(tx=>tx.wait());
    const api1addr = api.address
    const app1 = await controller.appMapping(0)
    const originApp1 = await attach("APICoin", api1addr) as APICoin
    await originApp1.depositToApp(app1, {value: parseEther("1")}).then(tx=>tx.wait())
    //
    const apiv2 = await deploy("ApiV2",[]) as ApiV2;
    await expect(originApp1.upgradeTo(apiv2.address)).emit(originApp1, originApp1.interface.events["Upgraded(address)"].name)
        .withArgs(apiv2.address);
    const upgradedV2 = await apiv2.attach(api1addr)
    expect(await upgradedV2.version()).eq("ApiV2")
    expect(await originApp1.balanceOf(app1)).eq(parseEther("1"))
  })

  it("upgrade app, beacon", async function (){
    const app_ = await deploy("Airdrop", []) as Airdrop
    const appBeacon = await deploy("UpgradeableBeacon", [app_.address]) as UpgradeableBeacon;
    const controller = await deploy("Controller", [ethers.constants.AddressZero, appBeacon.address]).then(res=>res as Controller);
    await controller.createApp("app 1", "a1", "app description", 3).then(tx=>tx.wait());

    const app1addr = await controller.appMapping(0);
    const originApp1 = await attach("APPCoin", app1addr) as APPCoin
    await originApp1.configResource({id:0, resourceId:"path0", weight:10, op: OP.ADD}).then(tx=>tx.wait())

    const appUpgradeableBeacon = await controller.appBase().then(addr=>attach("UpgradeableBeacon", addr))
        .then(c=>c as UpgradeableBeacon);
    // check owner
    expect(await appUpgradeableBeacon.owner()).eq(acc1);

    const v2 = await deploy("AppV2", []).then(res=>res as AppV2);
    await expect(appUpgradeableBeacon.upgradeTo(v2.address))
        .emit(appUpgradeableBeacon, appUpgradeableBeacon.interface.events["Upgraded(address)"].name)
        .withArgs(v2.address)
    // call new method
    const appV2 = await v2.attach(app1addr)
    expect(await appV2.version()).eq("App v2");
    expect(await originApp1.resourceConfigures(102).then(info=>info.pendingWeight)).eq(10)
    await expect(appV2.setPendingSeconds(0)).revertedWith(`only available on testnet`);
    let opFlag = await appV2.resourceConfigures(101).then(res=>res.pendingOP.toString());
    assert(opFlag == OP.NO_PENDING.toString(),
        `want NO_PENDING, actual ${opFlag}`)
    await appV2.configResource({id: 101, resourceId: 'default', weight: 101, op: OP.UPDATE}).then(tx=>tx.wait())
    expect(await originApp1.resourceConfigures(101).then(info=>info.pendingWeight)).eq(101)
  })
})
describe("ApiCoin", async function () {
  const signerArr = await ethers.getSigners();
  const [signer1, signer2, signer3] = signerArr;
  const [acc1, acc2, acc3] = await Promise.all(signerArr.map((s) => s.getAddress()));
  it("Should deposit to app", async function () {
    const api = (await deployProxy("APICoin", ["main coin", "mc", baseToken, []])) as APICoin;
    const app = (await deployApp("APPCoin", [
      api.address,
      acc1,
      "APP 1",
      "APP1", 1,
    ])) as APPCoin;

    expect(await app.apiCoin()).to.equal(api.address);
    //
    const spend = parseEther("1.23");
    const account = await api.signer.getAddress();
    let tx_:ContractTransaction
    await expect(
      api
        .depositToApp(app.address, { value: spend })
    )
        .emit(app, app.interface.events["TransferSingle(address,address,address,uint256,uint256)"].name)
      .withArgs(api.address, ethers.constants.AddressZero, account, 0, spend);
    await app.balanceOf(account, 0).then((res) => {
      console.log(`balance of app, user ${account}`, formatEther(res));
    });
    //
  });
  it("config resource weights", async function () {
    const api = (await deployProxy("APICoin", ["main coin", "mc", baseToken, []])) as APICoin;
    const app = (await deployApp("APPCoin", [
      api.address,
      acc1,
      "DO_NOT_DEPOSIT",
      "ALL_YOU_FUNDS_WILL_LOST", 1,
    ])) as APPCoin;
    // default resource weight 1, id 1, index 0
    let defaultConfig = await app.resourceConfigures(await app.FIRST_CONFIG_ID());
    assert(defaultConfig.weight.toNumber() == 1,`default weight should be 1 vs ${defaultConfig.weight}`)
    assert(defaultConfig.resourceId == 'default','default resourceId should be <default>')
    assert(defaultConfig.index == 0,'default resource index should be 0')
    // add new one, auto id 2, index 1
    await app
      .configResource({id: 0, resourceId: "path2", weight: 2, op: OP.ADD})
      .then((res) => res.wait())
      .then(dumpEvent)
    let config2 = await app.resourceConfigures(2)
    expect(config2.index == 1, 'index should be 1 for config 2');

    assert(await app.nextConfigId() == 103, 'next id should be 3')

    // update
    await app.configResource({id: 102, resourceId: "path2", weight:200, op: OP.UPDATE})
        .then(tx=>tx.wait())
    config2 = await app.resourceConfigures(102)
    assert(config2.pendingWeight.toNumber() == 200, 'pending weight should be updated')
    assert(config2.index == 1, 'index should be 1')

    // id mismatch resource id
    await expect(
      app.configResource({id: 101, resourceId: "pathN", weight: 3, op: OP.UPDATE})
    ).to.be.revertedWith(`id/resourceId mismatch`);
    // duplicate adding
    await expect(
        app.configResource({id: 0, resourceId: "path2", weight: 3, op: OP.ADD})
    ).to.be.revertedWith(`resource already added`);
    // batch
    await app
      .configResourceBatch([
        {id: 0, resourceId: 'p3', weight: 103, op: OP.ADD}, //add p3, id 103, index 2
        {id: 0, resourceId: 'p4', weight: 104, op: OP.ADD}, //add p4, id 104, index 3
        {id: 0, resourceId: 'p5', weight: 105, op: OP.ADD}, //add p5, id 105, index 4

        {id: 104, resourceId: 'p4', weight: 204, op: OP.UPDATE}, //update p4, id 4, index 3
        {id: 103, resourceId: 'p3', weight: 204, op: OP.DELETE}, //delete p3, id 3, index 2 -- delete
      ]) // index array [1, 2, 3, 4, 5] delete id 3 index 2 => [1, 2, 5, 4]
      .then((res) => res.wait());
    assert(await app.nextConfigId() == 106, 'next id should be 106');
    //
    const [list0,total0] = await app.listResources(0, 30);
    assert(list0.length == 5, `should have 5 items, actual ${list0.length}`);
    // hack pending seconds and flush configures.
    await app.setPendingSeconds(0).then(tx=>tx.wait())
    await app.flushPendingConfig().then(tx=>tx.wait())//.then(dumpEvent);

    const [list,total] = await app.listResources(0, 30);
    assert(list.length == 4, `should have 4 items, actual ${list.length}`);
    const [,,[path, w, index, pendingOP]] = list;
    assert(path == 'p5', 'resource id should be right')
    assert(w.toNumber() == 105, 'weight should be right')
    assert(index == 2, `index should be right, ${index} vs 3 `)
    assert(pendingOP.toString() == OP.NO_PENDING.toString(), `want no pending, ${pendingOP} vs ${OP.NO_PENDING} `)

    const nftAmount = await app.balanceOf(app.address, 105).then(res=>res.toNumber());
    assert( nftAmount == 105, `nft amount want 105 vs ${nftAmount}`);

    console.log(`config is `, await app.resourceConfigures(104))
    const nftAmount104 = await app.balanceOf(app.address, 104).then(res=>{
      return res.toNumber()
    });
    assert( nftAmount104 == 204, `nft amount want 204 vs ${nftAmount104}`);

  });
  it("check permission", async function () {
    const api = (await deployProxy("APICoin", ["main coin", "mc", baseToken, []])) as APICoin;
    const app = (await deployApp("APPCoin", [
      api.address,
      acc1,
      "APP 1",
      "APP1", 1,
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
      app2.safeTransferFrom(await app2.signer.getAddress(), api.address, 0, parseEther("1"), Buffer.from("")).then((res) => res.wait())
    ).to.be.revertedWith(`Not permitted`);

    await expect(
      app2
        .safeTransferFrom(await app2.signer.getAddress(), api.address, 0, parseEther("1"), Buffer.from(""))
        .then((res) => res.wait())
    ).to.be.revertedWith(`Not permitted`);
    //
    // await expect(
    //   app2.burn(parseEther("1"), Buffer.from("")).then((res) => res.wait())
    // ).to.be.revertedWith(`Not permitted`);

    await expect(app2.configResource({id:0, resourceId:"p0", weight:10, op:OP.ADD})).to.be.revertedWith(
      `not app owner`
    );
    await expect(app2.refund(app2.address)).to.be.revertedWith(
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
    const {api, app, app2} = await deployAndDeposit(signer1);
    // freeze acc1 by admin
    await app.freeze(acc1, true).then((res) => res.wait());
    await expect(
      app.forceWithdraw().then((res) => res.wait())
    ).to.be.revertedWith(`Frozen by admin`);
    await expect(
      app.withdrawRequest().then((res) => res.wait())
    ).to.be.revertedWith(`Account is frozen`);
    // unfreeze
    await app.freeze(acc1, false).then((res) => res.wait());
    await expect(
      app.forceWithdraw().then((res) => res.wait())
    ).to.be.revertedWith(`Withdraw request first`);
    await expect(app.withdrawRequest())
      .emit(app, app.interface.events["Frozen(address)"].name)
      .withArgs(acc1);
    await expect(
      app.forceWithdraw().then((res) => res.wait())
    ).to.be.revertedWith(`Waiting time`);

    // should transfer api coin from App to acc1
    await app.setForceWithdrawDelay(0).then((res) => res.wait());
    await expect(app.forceWithdraw())
      .emit(api, api.interface.events["Transfer(address,address,uint256)"].name)
      .withArgs(app.address, acc1, parseEther("1"));
    expect(await app.balanceOf(acc1, 0)).eq(0);

  });
  it("track charged users", async () => {
    const {api, app:appOwnerAcc2, app2:appSigner1} = await deployAndDeposit(signer2);
    await Promise.all([signer2, signer3].map(s=>{
      return api.connect(s).depositToApp(appOwnerAcc2.address, {value: parseEther("1")}).then(tx=>tx.wait())
    }))
    await appOwnerAcc2.charge(acc1, 1, Buffer.from(""), []).then(tx=>tx.wait())
    await appOwnerAcc2.chargeBatch([
      {account: acc1, amount: 1, data: Buffer.from(""), useDetail: [{id: 101, times: 100}]},
      {account: acc2, amount: 1, data: Buffer.from(""), useDetail: [{id: 101, times: 100}]},
      {account: acc3, amount: 1, data: Buffer.from(""), useDetail: [{id: 101, times: 100}]},

      {account: acc1, amount: 1, data: Buffer.from(""), useDetail: [{id: 101, times:  10}]},
      {account: acc2, amount: 1, data: Buffer.from(""), useDetail: [{id: 101, times: 100}]},
      {account: acc3, amount: 1, data: Buffer.from(""), useDetail: [{id: 101, times: 100}]},
    ]).then(tx=>tx.wait());
    const [users, total] = await appOwnerAcc2.listUser(0, 10);
    assert(total.eq(3), 'should be 3 users')
    assert(users[0][0] == acc1, `user 0 should be ${acc1}, actual ${users[0][0]}`)
    assert(users[0][1].eq(3), `user 0 should have spent 3 actual ${formatEther(users[0][1])}`)
    assert(users[1][1].eq(2), `user 1 should have spent 2 actual ${(users[0][1])}`)
    assert(users[2][1].eq(2), `user 2 should have spent 2 actual ${(users[0][1])}`)
    assert(users[1][0] == acc2 || users[1][0] == acc3, 'user 1 should be acc2 or acc3')
    assert(users[2][0] == acc2 || users[2][0] == acc3, 'user 2 should be acc2 or acc3')
    assert(users[1][0] !== users[2][0], 'user 1 should not be user 2')
    // check request counter
    const config = await appOwnerAcc2.resourceConfigures(101)
    assert(config.requestTimes.toNumber() == 510, `request times should be 610 vs ${config.requestTimes}`)
    const [usage] = await appOwnerAcc2.listUserRequestCounter(acc1, [101])
    assert(usage.toNumber() == 110, `user usage should be 110, vs ${usage}`)
  });
  it("charge and auto refund", async () => {
    const {api, app, app2} = await deployAndDeposit(signer1);
    // charge without refund
    await expect(app.charge(acc1, parseEther("0.1"), Buffer.from("扣费"), []))
        .to.be.emit(app, app.interface.events["TransferSingle(address,address,address,uint256,uint256)"].name)
        .withArgs(acc1, acc1, ethers.constants.AddressZero, 0, parseEther("0.1"))
    await expect(app.withdrawRequest()).emit(app, app.interface.events["Frozen(address)"].name)
        .withArgs(acc1)
    await expect(app.charge(acc1, parseEther("0.1"), Buffer.from("扣费"), []))
        .emit(app, app.interface.events["TransferSingle(address,address,address,uint256,uint256)"].name)
        .withArgs(acc1, ethers.constants.AddressZero, parseEther("0.8"))// burn
        .emit(api, api.interface.events["Transfer(address,address,uint256)"].name)
        .withArgs(app.address, acc1, parseEther("0.8")) // refund api code
    expect(1).eq(1);
  });
  it("airdrop", async () => {
    const {api, app, app2} = await deployAndDeposit(signer2, "Airdrop");
    const badApp2 = app2 as any as Airdrop
    await expect(badApp2.airdrop(acc1, parseEther('1'), "fail")).to.be.revertedWith(`not app owner`)
    const airdrop = app as any as Airdrop
    const tx = await airdrop.airdropBatch([acc1], [parseEther("10")], ['test']);
    await expect(tx).emit(airdrop, airdrop.interface.events["Drop(address,uint256,string)"].name)
        .withArgs(acc1, parseEther("10"), 'test')
    let [total, drop] = await airdrop.balanceOfWithAirdrop(acc1)
    assert( total.eq(parseEther("11")), `should be 11 app coin, ${total}`)
    assert( drop.eq(parseEther("10")), `should be 10 airdrop, ${drop}`)
    await expect(app.charge(acc1, parseEther("1"), Buffer.from("sub 1 left 1 + 9"), []))
        .emit(airdrop, airdrop.interface.events["Spend(address,uint256)"].name).withArgs(acc1, parseEther("1"))
        .emit(airdrop, airdrop.interface.events["TransferSingle(address,address,address,uint256,uint256)"].name)
        .withArgs(await app.signer.getAddress(), acc1, ethers.constants.AddressZero, 0, parseEther("0"));
    [total, drop] = await airdrop.balanceOfWithAirdrop(acc1)
    assert( total.eq(parseEther("10")), `should be 10 app coin, ${total}`)
    assert( drop.eq(parseEther("9")), `should be 9 airdrop, ${drop}`)
    assert(parseEther("1").eq(await airdrop.balanceOf(acc1, 0)), "should be 1 origin app coin")

    await expect(app.charge(acc1, parseEther("9.5"), Buffer.from("sub 9.5 left 0.5 + 0"), []))
        .emit(airdrop, airdrop.interface.events["Spend(address,uint256)"].name).withArgs(acc1, parseEther("9"))
        .emit(airdrop, airdrop.interface.events["TransferSingle(address,address,address,uint256,uint256)"].name)
        .withArgs(await app.signer.getAddress(), acc1, ethers.constants.AddressZero, 0, parseEther("0.5"));

    [total, drop] = await airdrop.balanceOfWithAirdrop(acc1)
    assert( total.eq(parseEther("0.5")), `should be 0.5 app coin, ${total}`)
    assert( drop.eq(parseEther("0")), `should be 0 airdrop, ${drop}`)
  });
  it("app as nft", async () => {
    const {api, app, app2} = await deployAndDeposit(signer1);
    const prefix = "data:application/json;base64,"
    const metaStr = await app.uri(0).then(str=>Buffer.from(str.substring(prefix.length), "base64").toString("UTF8"));
    const metaStrOfConfig = await app.uri(1).then(str=>Buffer.from(str.substring(prefix.length), "base64").toString());
    console.log(`meta info`, metaStr, metaStrOfConfig)
    JSON.parse(metaStr)
    JSON.parse(metaStrOfConfig)
  });
  it("track paid app", async () => {
    const {api, app, app2} = await deployAndDeposit(signer1);
    let [list,total] = await api.listPaidApp(acc1, 0, 10);
    assert(total.toNumber() == 1, "should have 1 paid app")
    assert(list[0] === app.address, "should be the right app")
    // create new app
    const appNew2 = await deployApp("APPCoin", [
      api.address,
      acc2, // set acc2 as app owner
      "APP 2",
      "APP2", 1
    ])
    await api
        .depositToApp(appNew2.address, { value: parseEther("1") })
        .then((res) => res.wait());

    [list,total] = await api.listPaidApp(acc1, 0, 10);
    assert(total.toNumber() == 2, "should have 2 paid app")
    assert(list[1] === appNew2.address, "should be the right app")

    // deposit to app1 again
    await api
        .depositToApp(app.address, { value: parseEther("1") })
        .then((res) => res.wait());

    [list,total] = await api.listPaidApp(acc1, 0, 10);
    assert(total.toNumber() == 2, "should have 2 paid app")
    assert(list[0] === app.address, "should be the right app")
  });
});
