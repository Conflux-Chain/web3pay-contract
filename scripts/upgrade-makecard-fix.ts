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
import {UpgradeableBeacon, App} from "../typechain";
import {ethers} from "hardhat";

async function main() {
    const [signer] = await ethers.getSigners();
    const deployer = signer.address;
    console.log(`upgrader: ${deployer}`);

    // Treat placeholder literals as "not provided" so a leftover
    // __APP_BEACON_ADDRESS_HERE__ falls through to APP_PROXY instead of
    // being used as a real beacon address.
    const appBeaconRaw = process.env.APP_BEACON?.trim() ?? "";
    const appProxyRaw = process.env.APP_PROXY?.trim() ?? "";
    const appBeacon = appBeaconRaw === "__APP_BEACON_ADDRESS_HERE__" ? "" : appBeaconRaw;
    const appProxy = appProxyRaw === "__APP_PROXY_ADDRESS_HERE__" ? "" : appProxyRaw;

    // 0) Read-only info (free, no gas) — print BEFORE any state-changing call so it
    //    shows even if the later deploy/upgrade fails (e.g. insufficient funds).
    if (appProxy) {
        const app = (await ethers.getContractFactory("App")).attach(appProxy) as App;
        console.log(`App proxy ${appProxy} link:        ${await app.link()}`);
        console.log(`App proxy ${appProxy} description: ${await app.description()}`);
    } else {
        console.log(`(set APP_PROXY to also read link/description of a specific App instance)`);
    }

    let beaconAddr: string;
    if (appBeacon) {
        beaconAddr = appBeacon;
        console.log(`using APP_BEACON=${beaconAddr}`);
    } else if (appProxy) {
        // BeaconProxy's typed contract does not expose beacon(), and the dynamic
        // ethers.Contract provider type clashes with hardhat's nested ethers copy.
        // Read the EIP-1967 *beacon* slot directly (App instances are BeaconProxy).
        // NOTE: 0x360894... is the implementation slot; the beacon slot is 0xa3f0...
        const beaconSlot = "0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50";
        const raw = await ethers.provider.getStorageAt(appProxy, beaconSlot);
        beaconAddr = ethers.utils.getAddress("0x" + raw.slice(-40));
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

    // 3) Sanity check: beacon now resolves to the new implementation.
    const newImpl = await beacon.implementation();
    console.log(`beacon implementation now: ${newImpl}`);

    console.log(`done. Verify via ReadFunctions / block explorer.`);
}

main().catch((error) => {
    console.error("upgrade failed:", error);
    process.exitCode = 1;
});
