import { expect } from "chai";
import { ethers } from "hardhat";
import {deploy, deployCardContracts, waitTx} from "../scripts/lib";
import {CardShop, Cards, CardTemplate} from "../typechain";

describe("Greeter", function () {
  it("Should ok", async function () {
    const {shop, template, inst} = await deployCardContracts();
    //
    await template.config({
      closeSaleAt: 0,
      description: "desc",
      duration: 3600,
      icon: "icon.ico",
      id: 0,
      level: 1,
      name: "name",
      openSaleAt: 3,
      price: 4,
      salesLimit: 2,
      listPrice: 100,
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