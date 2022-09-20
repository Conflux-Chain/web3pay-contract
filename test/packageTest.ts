import { expect } from "chai";
import { ethers } from "hardhat";
import {deploy, waitTx} from "../scripts/lib";
import {PackageInstance, PackageShop, PackageTemplate} from "../typechain";

describe("Greeter", function () {
  it("Should ok", async function () {
    const shop = await deploy("PackageShop", []) as PackageShop;
    const name = "package", symbol = "pkg"
    const inst = await deploy("PackageInstance", [name, symbol]) as PackageInstance;
    const template = await deploy("PackageTemplate", []) as PackageTemplate;
    await shop.setContracts(template.address, inst.address).then(waitTx)
    //
    await template.config({
      closeSaleAt: 0,
      description: "desc",
      duration: 3600,
      icon: "icon.ico",
      id: 0,
      name: "name",
      openSaleAt: 3,
      price: 4,
      salesLimit: 2,
      showPrice: 100,
      status: 1
    }).then(waitTx)
    let nextId = await template.nextId()
    console.log(`next id`, nextId)
    console.log(`config`, await template.getTemplate(nextId.sub(1)))
    await shop.buy(nextId.sub(1))
    console.log(`meta`, await inst.tokenURI(1)
        .then(
            res=>{
              console.log(`meta raw`, res)
              return Buffer.from(res.substring("data:application/json;base64,".length), "base64").toString()
            }
        )
    )
  });
});