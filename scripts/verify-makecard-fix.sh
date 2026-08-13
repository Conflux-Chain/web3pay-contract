#!/usr/bin/env bash
#
# 负面验证 makeCard 修复: 用非 cardShop 账户调用 makeCard, 断言其 revert。
# 使用 eth_call (静态调用), 不花 gas、不需要账户有余额。
# App 代理地址已内置 (按 chainId), 所以只需选网络即可直接运行。
#
# 用法:
#   NETWORK=net71 ./scripts/verify-makecard-fix.sh      # 测试网 (默认)
#   NETWORK=net1030 ./scripts/verify-makecard-fix.sh    # 主网

set -euo pipefail

NETWORK="${NETWORK:-net71}"

# net71 是用户口中的测试网(chainId 71), 对应 hardhat 的 test 网络
case "$NETWORK" in
  net71) HARDHAT_NETWORK="test" ;;
  *)     HARDHAT_NETWORK="$NETWORK" ;;
esac

# 测试网 RPC (主网 net1030 不生效, 使用 hardhat.config 内置地址)
export TEST_RPC_URL="${TEST_RPC_URL:-https://evmtestnet.confluxrpc.com}"

echo ">>> 负面验证 makeCard 修复 (网络: $NETWORK / hardhat: $HARDHAT_NETWORK)"
npx hardhat --network "$HARDHAT_NETWORK" run scripts/verify-makecard-fix.ts
