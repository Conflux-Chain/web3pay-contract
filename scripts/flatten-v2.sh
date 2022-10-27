if [[ -n "$1" ]]
then
  name=$1
  echo "$name"
  hardhat flatten contracts/v2/$name.sol > flatten/$name.txt
  exit
fi
declare -a arr=("AppCoinV2" "SwapExchange" "ApiWeightToken" "ApiWeightTokenFactory" "VipCoin" "VipCoinFactory" "App" "AppRegistry" "AppFactory" "CardShop" "CardTemplate" "CardTracker" "CardShopFactory")

## now loop through the above array
for name in "${arr[@]}"
do
   echo "$name"
   hardhat flatten contracts/v2/$name.sol > flatten/$name.txt
#   hardhat flatten contracts/v2/AppFactory.sol > flatten/AppFactory.txt
#   hardhat flatten contracts/upgrade-test/MyERC1967.sol > flatten/ERC1967Proxy.txt
#   hardhat flatten contracts/upgrade-test/MyBeaconProxy.sol > flatten/BeaconProxy.txt

#   hardhat flatten contracts/v2/ApiWeightToken.sol > flatten/ApiWeightToken.txt
#   hardhat flatten contracts/v2/App.sol > flatten/App.txt
done
