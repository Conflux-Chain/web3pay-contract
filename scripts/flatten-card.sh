declare -a arr=("Cards" "CardShop" "CardTemplate" "CardTracker")

## now loop through the above array
for name in "${arr[@]}"
do
   echo "$name"
   hardhat flatten contracts/v2/$name.sol > flatten/$name.txt
done
