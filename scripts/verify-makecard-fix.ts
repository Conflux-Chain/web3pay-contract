/**
 * Negative verification for the makeCard access-control fix.
 *
 * It calls App.makeCard from a NON-cardShop account via eth_call (static call,
 * no gas, no funds needed) and asserts the call reverts with
 * "App: caller is not cardShop". If it does NOT revert, the fix is not in effect.
 *
 * This is the behavioral proof that the previously-unprotected entry point is now
 * gated. Run it AFTER the upgrade script has upgraded the beacon.
 *
 * Usage:
 *   NETWORK=net71 ./scripts/verify-makecard-fix.sh
 *   (APP_PROXY is selected by network; override with export APP_PROXY=0x...)
 */
import {ethers} from "hardhat";
import {App} from "../typechain";

async function main() {
    const appProxyRaw = process.env.APP_PROXY?.trim() ?? "";
    const appProxy = appProxyRaw === "__APP_PROXY_ADDRESS_HERE__" ? "" : appProxyRaw;
    if (!appProxy) {
        throw new Error("APP_PROXY not set (select via NETWORK or export APP_PROXY=0x...)");
    }

    const app = (await ethers.getContractFactory("App")).attach(appProxy) as App;
    const cardShop = await app.cardShop();
    console.log(`App proxy : ${appProxy}`);
    console.log(`cardShop  : ${cardShop}`);

    // A random wallet that is definitely not the registered cardShop.
    const attacker = ethers.Wallet.createRandom().connect(ethers.provider);
    console.log(`attacker  : ${attacker.address} (should NOT be the cardShop)`);

    try {
        // callStatic simulates the call; a revert throws instead of consuming gas.
        await app.connect(attacker).callStatic.makeCard(attacker.address, 3, 1, 0);
        console.error("FAIL: makeCard did NOT revert for a non-cardShop caller");
        process.exitCode = 1;
        return;
    } catch (e: any) {
        const reason: string = e?.reason || e?.error?.message || String(e);
        if (reason.includes("caller is not cardShop")) {
            console.log("PASS: makeCard reverts for non-cardShop caller ✅  (fix verified)");
        } else {
            console.error("FAIL: makeCard reverted, but with unexpected reason:", reason);
            process.exitCode = 1;
        }
    }
}

main().catch((e) => {
    console.error(e);
    process.exitCode = 1;
});
