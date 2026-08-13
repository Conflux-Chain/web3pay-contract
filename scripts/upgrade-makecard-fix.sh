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
#   APP_BEACON   - App 的 UpgradeableBeacon 地址
#                 或
#   APP_PROXY    - 任一 App 代理地址 (如 Confura RPC Pro-Service 的 App 代理), 脚本会从中推导 beacon
#   NETWORK      - hardhat 网络名 (net1030=eSpace 主网, test=测试网)

set -euo pipefail

# ====================== 请填写以下占位符 ======================
PRIVATE_KEY="${PRIVATE_KEY:-__YOUR_PRIVATE_KEY_HERE__}"
APP_BEACON="${APP_BEACON:-__APP_BEACON_ADDRESS_HERE__}"
# 若不知道 APP_BEACON, 可改为填 APP_PROXY (二选一即可, 优先用 APP_BEACON)
APP_PROXY="${APP_PROXY:-__APP_PROXY_ADDRESS_HERE__}"
NETWORK="${NETWORK:-net1030}"
# =============================================================

# 若 PRIVATE_KEY 仍是占位符则报错退出
if [ "$PRIVATE_KEY" = "__YOUR_PRIVATE_KEY_HERE__" ]; then
  echo "ERROR: 请在脚本中填写 PRIVATE_KEY (或 export PRIVATE_KEY=...)" >&2
  exit 1
fi

# 两个地址占位符不能同时为空
if [ "$APP_BEACON" = "__APP_BEACON_ADDRESS_HERE__" ] && [ "$APP_PROXY" = "__APP_PROXY_ADDRESS_HERE__" ]; then
  echo "ERROR: 请在脚本中填写 APP_BEACON 或 APP_PROXY (或 export 对应环境变量)" >&2
  exit 1
fi

export PRIVATE_KEY
export APP_BEACON
export APP_PROXY

# 测试网 RPC (hardhat 配置中 network "test" 读取 TEST_RPC_URL)
# 使用 net1030 (主网) 时此变量不生效, 可忽略。
export TEST_RPC_URL="${TEST_RPC_URL:-https://evmtestnet.confluxrpc.com}"

echo ">>> 使用网络: $NETWORK"
echo ">>> beacon/env 参数已就绪, 开始执行升级..."

npx hardhat --network "$NETWORK" run scripts/upgrade-makecard-fix.ts
