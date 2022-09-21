import {verifyContract} from "./verify-scan";
import * as fs from "fs";
import {DEPLOY_CARD_INFO} from "./lib";

async function main() {
    const {shop, cards, template, tracker} = JSON.parse(fs.readFileSync(DEPLOY_CARD_INFO).toString())
    await Promise.all([
            verifyContract('CardTracker', tracker),
            verifyContract('CardTemplate', template),
            verifyContract('Cards', cards),
            verifyContract('CardShop', shop),
        ]
    )
}
if (module === require.main) {
    main().then()
}