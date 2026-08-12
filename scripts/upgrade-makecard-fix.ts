/**
 * Upgrade the App implementation to fix the unauthorized `makeCard` vulnerability.
 *
 * Mechanism:
 *   App instances are deployed behind a single shared UpgradeableBeacon
 *   (`appUpgradableBeacon`). Upgrading that beacon's implementation upgrades every
 *   App proxy at once (Confura RPC Pro-Service, ConfluxScan API Pro-Service, ...).
 *
 * Required parameters (no deploy-info JSON file needed):
 *   - PRIVATE_KEY   : env var. Private key of the beacon owner (who can call
 *                     UpgradeableBeacon.upgradeTo). This is the only "secret" input.
 *   - APP_BEACON    : env var. The App UpgradeableBeacon address.
 *                     OR
 *   - APP_PROXY     : env var. Any App proxy address (e.g. Confura's App proxy);
 *                     the beacon is derived from it via BeaconProxy.beacon().
 *
 * Network / RPC is taken from the hardhat network used to run this script, e.g.:
 *   npx hardhat --network net1030 run scripts/upgrade-makecard-fix.ts
 * (net1030 -> eSpace mainnet; set PRIVATE_KEY + APP_BEACON/APP_PROXY in env first)
 *
 * The caller (PRIVATE_KEY) must be the owner of the UpgradeableBeacon, otherwise
 * beacon.upgradeTo will revert with an "Ownable: caller is not the owner" error.
 */
import {deploy, waitTx} from "./lib";
import {UpgradeableBeacon, BeaconProxy, App} from "../typechain";
import {ethers} from "hardhat";

async function main() {
    const [signer] = await ethers.getSigners();
    const deployer = signer.address;
    console.log(`upgrader: ${deployer}`);

    const appBeacon = process.env.APP_BEACON?.trim();
    const appProxy = process.env.APP_PROXY?.trim();

    let beaconAddr: string;
    if (appBeacon) {
        beaconAddr = appBeacon;
        console.log(`using APP_BEACON=${beaconAddr}`);
    } else if (appProxy) {
        const proxy = (await ethers.getContractFactory("BeaconProxy")).attach(appProxy) as BeaconProxy;
        beaconAddr = await proxy.beacon();
        console.log(`derived beacon ${beaconAddr} from APP_PROXY=${appProxy}`);
    } else {
        throw new Error("Missing required env var: set APP_BEACON or APP_PROXY");
    }

    // 1) Deploy the new (fixed) App implementation.
    const impl = await deploy("App", []);
    if (!impl) {
        throw new Error("failed to deploy new App implementation");
    }
    console.log(`new App impl: ${impl.address}`);

    // 2) Point the beacon at the new implementation (owner-only).
    const beacon = (await ethers.getContractFactory("UpgradeableBeacon")).attach(beaconAddr) as UpgradeableBeacon;
    const currentImpl = await beacon.implementation();
    console.log(`current App impl: ${currentImpl}`);
    if (currentImpl.toLowerCase() === impl.address.toLowerCase()) {
        console.log(`beacon already points to the new implementation; nothing to do.`);
        return;
    }

    const tx = await beacon.upgradeTo(impl.address);
    await waitTx(tx);
    console.log(`upgraded. beacon ${beaconAddr} now points to App impl ${impl.address}`);

    // 3) Sanity check: the proxy now resolves to the new implementation.
    const probe = (await ethers.getContractFactory("App")).attach(appProxy ?? beaconAddr) as App;
    console.log(`done. Verify via ReadFunctions / block explorer.`);
}

main().catch((error) => {
    console.error("upgrade failed:", error);
    process.exitCode = 1;
});
