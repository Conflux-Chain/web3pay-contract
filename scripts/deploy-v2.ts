import {attach, deployV2App, networkInfo, timestampLog, tokensEthFork, tokensNet71, waitTx} from "./lib";
import {formatEther, formatUnits, parseEther} from "ethers/lib/utils";
import {AppCoinV2, ERC1967Proxy, SwapExchange} from "../typechain";
import {ethers, upgrades} from "hardhat";

async function checkContract(addr:string) {
    console.log(`check contract at ${addr}`)
    const tmpContract = await ethers.getContractAt("SwapExchange", addr, )
    console.log(`contract is `, tmpContract)
}
async function main() {
    timestampLog()
    const  {signer, account:acc1} = await networkInfo()
    // const {v2app, exchange} = await deployV2App(tokensNet71.usdt, tokensNet71.__router)
    // await checkContract(exchange.address);
    await deploy(acc1);
}
async function deploy(acc1: string) {
    // AppCoin2 deployed to: 0xe9E96C30FC8b7898be01313379ac491d081D45a4
    // SwapExchange deployed to: 0x292F3970440529DdD3B88ce7b69D3A38adb7F164

    const {v2app, exchange, vipCoin, appX} = await deployV2App(tokensEthFork.usdt, tokensEthFork.__router)
    console.log(`deploy v2 ok`)
    // const exchange = await attach("SwapExchange", "0x292F3970440529DdD3B88ce7b69D3A38adb7F164") as SwapExchange;
    const acAmount = 1//parseEther("1")
    const inAmt = await exchange.previewDepositETH(acAmount);
    await exchange.depositETH(acAmount * 2, acc1, {value: inAmt.mul(2)}).then(waitTx).then(({transactionHash})=>{
        console.log(`deposit eth tx hash ${transactionHash}`)
    })
    // const app = await attach("AppCoinV2","0xe9E96C30FC8b7898be01313379ac491d081D45a4") as AppCoinV2;
    const balance = await v2app.balanceOf(acc1);
    console.log(`app balance is ${balance} ${formatUnits(balance, 6)}, decimals ${await v2app.decimals()}`)
    await v2app.approve(exchange.address, acAmount).then(waitTx)
    console.log(`allowance`, await v2app.allowance(acc1, exchange.address))
    const {transactionHash} = await exchange.withdrawETH(acAmount, 0, acc1).then(waitTx);
    console.log(`withdraw transactionHash ${transactionHash}`)
    // vip coin
    // await vipCoin.mint(acc1, 1, 2, Buffer.from("")).then(waitTx).then(()=>{
    //     console.log(`vip coin minted`)
    // })
    // deposit to appX
    await v2app.approve(appX.address, acAmount).then(waitTx)
    console.log(`allowance appx`, await v2app.allowance(acc1, appX.address), "app coin", await appX.appCoin())
    await appX.deposit(acAmount, acc1).then(waitTx)
    console.log(`app x balance ${await appX.balanceOf(acc1)}`)
}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
