declare -a arr=("AppCoinV2" "SwapExchange" "ApiWeightToken" "ApiWeightTokenFactory" "VipCoin" "VipCoinFactory" "App" "AppRegistry" "AppFactory" "Cards" "CardShop" "CardTemplate" "CardTracker")

## now loop through the above array
for name in "${arr[@]}"
do
   echo "$name"
   hardhat flatten contracts/v2/$name.sol > flatten/$name.txt
#   hardhat flatten contracts/v2/AppFactory.sol > flatten/AppFactory.txt
#   hardhat flatten contracts/upgrade-test/MyERC1967.sol > flatten/ERC1967Proxy.txt
#   hardhat flatten contracts/upgrade-test/MyBeaconProxy.sol > flatten/BeaconProxy.txt
done
