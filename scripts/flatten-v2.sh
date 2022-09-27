declare -a arr=("AppCoinV2" "SwapExchange" "ApiWeightToken" "ApiWeightTokenFactory" "VipCoin" "App" "AppRegistry" "Cards" "CardShop" "CardTemplate" "CardTracker")

## now loop through the above array
for name in "${arr[@]}"
do
   echo "$name"
   hardhat flatten contracts/v2/$name.sol > flatten/$name.txt
done
