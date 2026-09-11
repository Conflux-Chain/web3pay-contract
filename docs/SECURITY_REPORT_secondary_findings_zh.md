# Web3Pay `App.makeCard` 英文报告与次要发现重评估

## 结论

该英文报告的主问题是对已知 `App.makeCard` 未授权调用漏洞的英文复述和扩展分析。当前代码已经在 `contracts/v2/App.sol` 中加入 `cardShop` 调用方校验，主漏洞入口已关闭。

报告中提出的 conditional-Critical 资金损失链条在旧实现下具备理论可行性：攻击者可无权限膨胀 `totalCharged`，随后拥有 `TAKE_PROFIT_ROLE` 的 payee 可在账本上限内执行 `takeProfit`。但提款步骤仍依赖授权角色，且当前实现已阻断外部伪造 `totalCharged` 的入口，因此不构成当前线上可达的无权限资金盗取路径。

结合线上使用方式，次要发现多数属于低概率或边缘路径问题：V1 不再使用；`AppConfig.flushPendingConfig()` 通常在配置后马上调用，不会长期混合未成熟 pending 项；`listResources()` 当前业务一页读取完成，基本不使用 `offset > 0` 分页。

## 本次处理

- 删除不再维护和不再使用的 V1 合约族、V1 测试、V1 部署/辅助脚本和对应文档。
- 修复 `AppConfig._flushPendingConfig()` 未分配内存数组导致的 pending 项回写 panic，并改为安全倒序循环，避免 `continue` 路径触发 `uint` 下溢。
- 修复 `AppConfig.listResources()` 忽略 `offset` 导致分页结果错误的问题。
- 修复 `VipCoinWithdraw._withdrawForEth()` 忽略 `receiver`、不清理 hook allowance、允许任意 hook 的问题。
- 修复 `ReadFunctions` 与 `VipCoinFactory` 新部署时的 first-caller-wins owner 初始化窗口。

## 次要发现重评估

| ID | 原发现 | 触发条件 | 当前风险 | 处理 |
| --- | --- | --- | --- | --- |
| F-1 | `forceWithdrawEth(receiver, hook, ethMin)` 实际把 ETH 发给 `msg.sender`，事件却记录 `receiver`；hook 可由调用者指定且 allowance 不清理 | 用户调用 ETH 强制提现，且 `receiver != msg.sender` 或传入非官方 hook | Low；主要是边缘提现路径与事件一致性/集成风险 | 已修复：ETH 发给 `receiver`，hook 限制为 registry exchanger，调用前后清理 allowance |
| F-2 | `_flushPendingConfig()` 对未分配的 `newPendingArray` 写入；旧倒序循环在未成熟项 `continue` 时也可能下溢 | pending 队列中存在未达到 `pendingSeconds` 的配置时调用 `flushPendingConfig()` | Low/Medium；线上若配置后马上 flush 或没有混合成熟时间，则通常不触发 | 已修复：按 pending 队列长度分配临时数组，使用安全倒序循环，并只回写未成熟项 |
| F-3 | V1 `APPCoin.charge()` 与 `chargeBatch()` 权限不一致 | 仅 V1 仍被使用且调用单笔 `charge()` 时触发 | Not Applicable；V1 不再使用 | 已删除 V1 合约和相关入口 |
| F-4 | `listResources(offset, limit)` 忽略 `offset` | 仅 `offset > 0` 的分页查询触发 | Informational；业务当前一页读取完成，基本不触发 | 已修复：读取 `indexArray[offset + i]` |
| F-5 | `ReadFunctions.setOwner()` 与旧 `TokenRouter` 初始化 first-caller-wins | 部署后 owner 未在同一流程中及时设置 | Informational；已部署实例若 owner 已设置则无运行期影响 | 已删除旧 `TokenRouter`，并让 `ReadFunctions.initialize()` / `VipCoinFactory.initialize()` 在代理初始化时设置 owner |

## 评级建议

- `App.makeCard` 主漏洞：历史有效漏洞，当前已知已修；若重复提交，不应作为新的主漏洞重复计奖。
- 次要发现：整体按 Low/Informational 处理；不构成当前线上紧急升级理由。
- 工程处理：适合随维护升级合并，降低边缘路径风险和旧代码误用风险。
