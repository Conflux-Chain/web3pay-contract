import {verifyContract} from "./verify-scan";
import fs from "fs";
import {DEPLOY_V2_INFO} from "./lib";

async function main() {
    const chainId = 71;
    const {AppCoinV2, exchangeImpl, apiWeightTokenImpl, apiWeightFactoryImpl, vipCoinFactoryImpl,
        appFactoryImpl, appRegistryImpl, appImpl,
        exchangeProxy, apiWeightFactoryProxy, vipCoinFactoryProxy, appFactoryProxy, appRegistryProxy}
        = JSON.parse(fs.readFileSync(DEPLOY_V2_INFO.replace(".json", `.chain-${chainId}.json`)).toString())
    await Promise.all([
            verifyContract('AppCoinV2', AppCoinV2),
            verifyContract('SwapExchange', exchangeImpl),
            verifyContract('ApiWeightToken', apiWeightTokenImpl),
            verifyContract('ApiWeightTokenFactory', apiWeightFactoryImpl),
            verifyContract('VipCoinFactory', vipCoinFactoryImpl),
            verifyContract('AppFactory', appFactoryImpl),
            verifyContract('AppRegistry', appRegistryImpl),

            verifyContract('ERC1967Proxy', exchangeProxy),
            verifyContract('ERC1967Proxy', apiWeightFactoryProxy),
            verifyContract('ERC1967Proxy', vipCoinFactoryProxy),
            verifyContract('ERC1967Proxy', appFactoryProxy),
            verifyContract('ERC1967Proxy', appRegistryProxy),

            verifyContract('App', appImpl),
            // verifyContract('BeaconProxy', 'created app address'),
        ]
    )
}

if (module === require.main) {
    main().then()
}