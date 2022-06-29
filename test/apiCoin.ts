import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { APICoin, APPCoin } from "../typechain";
import { ContractReceipt } from "ethers";
const {
  utils: { formatEther, parseEther },
} = ethers;
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
describe("ApiCoin", function () {
  it("Should deposit to app", async function () {
    const api = (await deployProxy("APICoin", [])) as APICoin;
    const app = (await deployProxy("APPCoin", [
      api.address,
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
    const app = (await deployProxy("APPCoin", [
      api.address,
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
    expect(app.setResourceWeight(index, "pathN", 3)).to.be.revertedWith(
      `invalid index`
    );
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
});
