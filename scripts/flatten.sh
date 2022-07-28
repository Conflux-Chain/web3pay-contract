declare -a arr=("APPCoin" "APICoin" "Controller" "TokenRouter" "Airdrop")

## now loop through the above array
for name in "${arr[@]}"
do
   echo "$name"
   hardhat flatten contracts/$name.sol > flatten/$name.txt
done
#  proxy
hardhat flatten ./contracts/upgrade-test/MyERC1967.sol > flatten/MyERC1967Proxy.txt
hardhat flatten ./contracts/upgrade-test/MyBeaconProxy.sol > flatten/MyBeaconProxy.txt
