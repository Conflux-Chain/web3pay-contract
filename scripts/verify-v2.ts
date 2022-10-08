import {verifyContract} from "./verify-scan";
import fs from "fs";
import {DEPLOY_V2_INFO} from "./lib";

async function main() {
    const chainId = 71;
    const [,,name, addr] = process.argv;
    if (name) {
        await verifyContract(name, addr)
        return
    }
    const {AppCoinV2, exchangeImpl, apiWeightTokenImpl, apiWeightFactoryImpl, vipCoinFactoryImpl,
        appFactoryImpl, appRegistryImpl, appImpl,
        cardTemplateImpl, cardTrackerImpl, cardShopImpl,
        exchangeProxy, apiWeightFactoryProxy, vipCoinFactoryProxy, appFactoryProxy, appRegistryProxy}
        = JSON.parse(fs.readFileSync(DEPLOY_V2_INFO.replace(".json", `.chain-${chainId}.json`)).toString());
    await Promise.all([
            verifyContract('AppCoinV2', AppCoinV2),
            verifyContract('SwapExchange', exchangeImpl),
            verifyContract('ApiWeightToken', apiWeightTokenImpl),
            verifyContract('ApiWeightTokenFactory', apiWeightFactoryImpl),
            verifyContract('VipCoinFactory', vipCoinFactoryImpl),
            verifyContract('AppFactory', appFactoryImpl),
            verifyContract('AppRegistry', appRegistryImpl),
            verifyContract('CardTemplate', cardTemplateImpl),
            verifyContract('CardTracker', cardTrackerImpl),
            verifyContract('CardShop', cardShopImpl),

            verifyContract('BeaconProxy', exchangeProxy),
            verifyContract('BeaconProxy', apiWeightFactoryProxy),
            verifyContract('BeaconProxy', vipCoinFactoryProxy),
            verifyContract('BeaconProxy', appFactoryProxy),
            verifyContract('BeaconProxy', appRegistryProxy),

            verifyContract('App', appImpl),
            // verifyContract('BeaconProxy', 'a beacon address'),
            // verifyContract('ERC1967Proxy', 'a 1967 address'),
        ]
    )
}

if (module === require.main) {
    main().then()
}