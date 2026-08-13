#!/usr/bin/env bash
#
# 运行 makeCard 漏洞修复的合约升级脚本。
# 用法:
#   1. 把下面的占位符替换成真实值 (或直接 export 环境变量后再运行本脚本)。
#   2. 确保已安装依赖: yarn install
#   3. 执行: bash scripts/upgrade-makecard-fix.sh
#
# 所需参数:
#   PRIVATE_KEY  - App UpgradeableBeacon 的 owner 私钥 (谁可以调用 upgradeTo)
#   APP_BEACON   - App 的 UpgradeableBeacon 地址 (可选; 不填则按网络用 APP_PROXY 推导)
#   APP_PROXY    - 任一 App 代理地址, 脚本会从中推导 beacon。
#                  已按网络预填: net1030=主网 Confura 代理, net71/test=测试网代理。
#                  可用 export APP_PROXY=... 覆盖。
#   NETWORK      - 网络选择: net1030=eSpace 主网, net71(或 test)=测试网(chainId 71)

set -euo pipefail

# ====================== 网络与地址配置 ======================
# PRIVATE_KEY 仍需你填写 (beacon owner 私钥)。
# APP_PROXY 按网络自动选择, 也可用 export APP_PROXY=... 覆盖。
PRIVATE_KEY="${PRIVATE_KEY:-__YOUR_PRIVATE_KEY_HERE__}"
APP_BEACON="${APP_BEACON:-__APP_BEACON_ADDRESS_HERE__}"
NETWORK="${NETWORK:-net1030}"

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
  *)          # 其他网络: 留占位符, 由下方校验拦截
    APP_PROXY="${APP_PROXY:-__APP_PROXY_ADDRESS_HERE__}" ;;
esac
# =============================================================

# 将占位符字面量视为"未填写", 避免被当成真实地址使用
[ "$PRIVATE_KEY" = "__YOUR_PRIVATE_KEY_HERE__" ] && PRIVATE_KEY=""
[ "$APP_BEACON" = "__APP_BEACON_ADDRESS_HERE__" ] && APP_BEACON=""
[ "$APP_PROXY" = "__APP_PROXY_ADDRESS_HERE__" ] && APP_PROXY=""

# 校验
if [ -z "$PRIVATE_KEY" ]; then
  echo "ERROR: 请在脚本中填写 PRIVATE_KEY (或 export PRIVATE_KEY=...)" >&2
  exit 1
fi
if [ -z "$APP_BEACON" ] && [ -z "$APP_PROXY" ]; then
  echo "ERROR: 请在脚本中填写 APP_BEACON 或 APP_PROXY (或 export 对应环境变量)" >&2
  exit 1
fi

export PRIVATE_KEY
export APP_BEACON
export APP_PROXY

# 测试网 RPC (hardhat 配置中 network "test" 读取 TEST_RPC_URL)
# 使用 net1030 (主网) 时此变量不生效, 可忽略。
export TEST_RPC_URL="${TEST_RPC_URL:-https://evmtestnet.confluxrpc.com}"

echo ">>> 使用网络: $NETWORK (hardhat: $HARDHAT_NETWORK)"
echo ">>> APP_PROXY: $APP_PROXY"
echo ">>> beacon/env 参数已就绪, 开始执行升级..."

npx hardhat --network "$HARDHAT_NETWORK" run scripts/upgrade-makecard-fix.ts
