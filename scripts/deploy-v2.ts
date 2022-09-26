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
    // await checkContract(exchange.address);
    await deploy(acc1);
}
async function deploy(acc1: string) {
    const {usdt, __router} = tokensNet71;
    const {v2app, exchange, appX, assetToken} = await deployV2App(usdt, __router)
    // const {v2app, exchange, vipCoin, appX} = await deployV2App(tokensEthFork.usdt, tokensEthFork.__router)
    console.log(`deploy v2 ok`)
    const acAmount = 1//parseEther("1")
    const inAmt = await exchange.previewDepositETH(acAmount);
    await exchange.depositETH(acAmount * 3, acc1, {value: inAmt.mul(3)}).then(waitTx).then(({transactionHash})=>{
        console.log(`deposit eth tx hash ${transactionHash}`)
    })
    const balance = await v2app.balanceOf(acc1);
    console.log(`app balance is ${balance} ${formatUnits(balance, 6)}, decimals ${await v2app.decimals()}`)
    await v2app.approve(exchange.address, acAmount).then(waitTx)
    console.log(`allowance`, await v2app.allowance(acc1, exchange.address))
    const {transactionHash} = await exchange.withdrawETH(acAmount, 0, acc1).then(waitTx);
    console.log(`withdraw transactionHash ${transactionHash}`)
    // deposit to appX through app coin
    await v2app.approve(appX.address, acAmount).then(waitTx)
    console.log(`allowance appx`, await v2app.allowance(acc1, appX.address), "app coin", await appX.appCoin())
    await appX.deposit(acAmount, acc1).then(waitTx)
    console.log(`app x balance ${await appX.balanceOf(acc1)}`)
    // deposit to app directly
    await exchange.depositAppETH(appX.address, acAmount, acc1, {value: inAmt.mul(2)}).then(waitTx);
    // withdraw base asset
    await appX.withdraw(acc1, true).then(waitTx);

    await exchange.depositAppETH(appX.address, acAmount, acc1, {value: inAmt.mul(2)}).then(waitTx);
    // withdraw
    await appX.requestForceWithdraw().then(waitTx)
    console.log(`requestForceWithdraw ok`)
    await appX.forceWithdrawEth(acc1, exchange.address, 0).then(waitTx);
    console.log(`app x balance after withdraw ${await appX.balanceOf(acc1)}`)

    console.log(`base asset balance ${await assetToken.balanceOf(acc1)}`)
    await assetToken.approve(appX.address, acAmount).then(waitTx)
    await appX.depositAsset(acAmount, acc1).then(waitTx)
}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
