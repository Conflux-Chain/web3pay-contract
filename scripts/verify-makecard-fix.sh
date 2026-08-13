#!/usr/bin/env bash
#
# 负面验证 makeCard 修复: 用非 cardShop 账户调用 makeCard, 断言其 revert。
# 使用 eth_call (静态调用), 不花 gas、不需要账户有余额。
#
# 用法:
#   NETWORK=net71 ./scripts/verify-makecard-fix.sh      # 测试网
#   NETWORK=net1030 ./scripts/verify-makecard-fix.sh    # 主网
#   (APP_PROXY 按网络自动选择; 可用 export APP_PROXY=0x... 覆盖)

set -euo pipefail

APP_PROXY="${APP_PROXY:-__APP_PROXY_ADDRESS_HERE__}"
NETWORK="${NETWORK:-net71}"

# net71 是用户口中的测试网(chainId 71), 对应 hardhat 的 test 网络
case "$NETWORK" in
  net71) HARDHAT_NETWORK="test" ;;
  *)     HARDHAT_NETWORK="$NETWORK" ;;
esac

# 按网络预填默认 APP_PROXY (可用 export APP_PROXY=... 覆盖)
case "$NETWORK" in
  net1030)    # eSpace 主网
    APP_PROXY="${APP_PROXY:-0x7F55828E334e63065B88055776db3A58734220Ad}" ;;
  net71|test) # eSpace 测试网 (chainId 71)
    APP_PROXY="${APP_PROXY:-0x607362A5326A2F9Eede7678c32A75aBA8b91486F}" ;;
  *)          # 其他网络: 留占位符, 由脚本内校验拦截
    APP_PROXY="${APP_PROXY:-__APP_PROXY_ADDRESS_HERE__}" ;;
esac

# 占位符视为未填写
[ "$APP_PROXY" = "__APP_PROXY_ADDRESS_HERE__" ] && APP_PROXY=""

export APP_PROXY
# 测试网 RPC (主网不生效)
export TEST_RPC_URL="${TEST_RPC_URL:-https://evmtestnet.confluxrpc.com}"

if [ -z "$APP_PROXY" ]; then
  echo "ERROR: 未提供 APP_PROXY (请 export APP_PROXY=0x... 或选择已知网络)" >&2
  exit 1
fi

echo ">>> 负面验证 makeCard 修复 (网络: $NETWORK / hardhat: $HARDHAT_NETWORK, APP_PROXY: $APP_PROXY)"
npx hardhat --network "$HARDHAT_NETWORK" run scripts/verify-makecard-fix.ts
