import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { APICoin, APPCoin } from "../typechain";
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
        .then((receipt) => {
          console.log(
            receipt.events
              ?.map((e) => `${e.address} ${e.event}, ${e.args}`)
              .join("\n")
          );
          return receipt;
        })
    )
      .emit(app, app.interface.events["Transfer(address,address,uint256)"].name)
      .withArgs(ethers.constants.AddressZero, account, spend);
    await app.balanceOf(account).then((res) => {
      console.log(`balance of app, user ${account}`, formatEther(res));
    });
    //
  });
});
