#!/usr/bin/env bash
#
# 源码验证 (一键): 在 ConfluxScan 浏览器上验证升级后的 App 实现合约源码。
#   1. hardhat flatten 生成单文件源码 flatten/App.txt
#   2. 设置 TEST_SCAN_URL / TEST_RPC_URL (已内置测试网地址, 可用环境变量覆盖)
#   3. 运行 verify-scan.ts 对 APP_IMPL 做验证
#
# 用法:
#   NETWORK=net71 ./scripts/verify-makecard-src.sh      # 测试网 (默认)
#   NETWORK=net1030 ./scripts/verify-makecard-src.sh    # 主网
# 覆盖参数:
#   APP_IMPL       - 升级后的 App 实现合约地址
#   TEST_SCAN_URL  - 浏览器 API 地址
#   TEST_RPC_URL   - 节点 RPC 地址

set -euo pipefail

NETWORK="${NETWORK:-net71}"

case "$NETWORK" in
  net71|test) HARDHAT_NETWORK="test";   SCAN_URL="https://evmtestnet.confluxscan.org" ;;
  net1030)    HARDHAT_NETWORK="net1030"; SCAN_URL="https://evm.confluxscan.org" ;;
  *)          HARDHAT_NETWORK="$NETWORK"; SCAN_URL="${TEST_SCAN_URL:-https://evmtestnet.confluxscan.org}" ;;
esac

# 升级后的 App 实现合约地址 (可用 export APP_IMPL=0x... 覆盖)
export APP_IMPL="${APP_IMPL:-0x11ef6d33004FFCee427783dd9A73e208B87c90AA}"
export TEST_SCAN_URL="${TEST_SCAN_URL:-$SCAN_URL}"
export TEST_RPC_URL="${TEST_RPC_URL:-https://evmtestnet.confluxrpc.com}"

mkdir -p flatten
echo ">>> flatten contracts/v2/App.sol -> flatten/App.txt"
npx hardhat flatten contracts/v2/App.sol > flatten/App.txt

echo ">>> verify source on ${TEST_SCAN_URL} (impl ${APP_IMPL})"
npx hardhat --network "$HARDHAT_NETWORK" run scripts/verify-scan.ts
