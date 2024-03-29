import { expect } from "chai";
import { ethers } from "hardhat";
import {deploy, deployCardContracts, waitTx} from "../scripts/lib";
import {CardShop, Cards, CardTemplate} from "../typechain";

describe("Greeter", function () {
  it("Should ok", async function () {
    const {shop, template, inst} = await deployCardContracts();
    //
    await template.config({
      description: "desc",
      duration: 3600,
      icon: "icon.ico",
      id: 0,
      level: 1,
      name: "name",
      price: 4,
      status: 1
    }).then(waitTx)
    let nextId = await template.nextId()
    console.log(`next id`, nextId)
    console.log(`config`, await template.getTemplate(nextId.sub(1)))
    await shop.buy(nextId.sub(1))
    console.log(`meta`, await inst.uri(1)
        .then(
            res=>{
              console.log(`meta raw`, res)
              return Buffer.from(res.substring("data:application/json;base64,".length), "base64").toString()
            }
        )
    )
  });
});