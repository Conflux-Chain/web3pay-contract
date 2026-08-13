# 漏洞报告（中文翻译 + 攻击者收益分析）

> 漏洞对象：`App.makeCard` 可被外部无授权调用
> 涉及文件：`contracts/v2/App.sol`、`contracts/v2/CardShop.sol`
> 原文语言：英文

---

## 一、漏洞报告翻译

**漏洞名称：** Web3Pay 的 `App.makeCard` 可被外部无授权调用，导致无抵押 VIP 代币铸造及 `totalCharged` 计费数据被恶意膨胀

**受影响项目：** web3pay-contract — `contracts/v2/App.sol`（`makeCard`）、`contracts/v2/CardShop.sol`（付费路径）

### 漏洞描述

`App.makeCard(address to, uint tokenId, uint amount, uint totalPrice)` 可被外部直接调用，既无访问控制修饰符，也未对调用方设置白名单。该方法会为 `TOKEN_ID_AIRDROP` 之上的代币 ID（包括 `TOKEN_ID_VIP = 3`）铸造 `vipCoin` 这类 ERC1155 代币，并将调用方传入的 `totalPrice` 累加到 `totalCharged` 中。设计上，预期的调用方 `CardShop` 本应在用户完成支付之后才会触发该流程，但直接调用可绕过这一支付校验。生产环境部署脚本在 eSpace 主网上通过本合约创建了 Confura RPC Pro-Service 和 ConfluxScan API Pro-Service 两个应用。

### 影响

任何调用方都可以在不付款的情况下铸造付费层级的 VIP 会员代币，并破坏计费账目核算。调用 `makeCard(attacker, 3, 1, MAX_UINT - totalCharged)` 可使 `totalCharged` 达到饱和状态，导致此后任何正向的 `charge()` 或付费卡片的计费累加都发生溢出并回滚，且这种状态将持续到合约升级为止。需要说明的是，单纯的数值膨胀并不会凭空生成 ERC4626 资产，也不会允许无权限提现；`takeProfit` 仍需要 `TAKE_PROFIT_ROLE` 角色权限以及足够的由 App 持有的份额。

### 证据

- `contracts/v2/App.sol:119-129` 将 `makeCard` 定义为不带任何修饰符的 `external` 函数；其内部调用 `vipCoin.mint(...)`，并执行 `totalCharged += totalPrice`。
- `contracts/v2/CardShop.sol:37-72` 强制要求 ETH 支付，并在 `:90-105` 处于支付完成后才调用 `_callMakeCard`。
- `contracts/v2/App.sol:59-76` 中 `takeProfit` 与 `takeProfitAsEth` 的边界计算均依赖 `totalCharged`。
- `scripts/deploy-prod.ts:36-70` 创建了生产环境中的 Confura 与 Scan 应用。

### 漏洞代码

```solidity
// contracts/v2/App.sol:119-129
function makeCard(address to, uint tokenId, uint amount, uint totalPrice) external override {
    if (amount > 0) {
        // 当 amount 为 0 时，仅累加 totalPrice。
        // TOKEN_ID_AIRDROP(1) 与 TOKEN_ID_COIN(0) 为保留 ID。
        require(tokenId > TOKEN_ID_AIRDROP, "invalid token id");
        vipCoin.mint(to, tokenId, amount, ""); // <-- 无抵押铸造，无支付校验，无角色校验
    }
    totalCharged += totalPrice; // <-- 任意调用方均可进行恶意膨胀
    appRegistry.addUser(to);
}
```

### 概念验证（PoC）

```js
// eSpace 上任何 EOA 均可直接调用已部署的 App 实现合约（web3.js 风格）：
const app = new web3.eth.Contract(App.abi, '<Confura RPC Pro-Service 的 App 代理地址>');

// 不付款即可向攻击者铸造付费层级 VIP 会员代币（tokenId=3）：
await app.methods.makeCard(attackerAddress, 3, 1, 0).send({from: attackerAddress});

// 永久性破坏计费账目（使 totalCharged 饱和 —— 之后所有的
// charge()/付费卡片累加都将溢出并回滚）：
const max = '0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';
await app.methods.makeCard(attackerAddress, 3, 1, max - await app.methods.totalCharged().call()).send({from: attackerAddress});
```

### 修复建议

将 `makeCard` 的调用权限限制为已注册的 `cardShop` 或某个专门的角色。对于 `totalPrice`，应仅依据卡片模板与数量进行计算（例如 `template.price * count`），而非直接接受调用方传入的值。

---

## 二、攻击者收益分析（代码核查）

**结论先行：对“随机外部攻击者”而言，该漏洞几乎不能带来链上直接经济收益；它主要提供“免费 VIP 身份（取决于链下权益）”以及“计费拒绝服务（DoS）”两类影响。真正能造成资金损失的路径（超额抽走金库资产）只对持有 `TAKE_PROFIT_ROLE` 的角色（即 owner）有效，攻击者通常并不具备该角色。**

### 1. 免费铸造 VIP 代币 —— 链上无实质效用，收益取决于链下权益

- `makeCard` 内有 `require(tokenId > TOKEN_ID_AIRDROP)`，即 `tokenId` 必须 ≥ 2。攻击者**无法铸造 `TOKEN_ID_COIN = 0`**（真正的 API 额度，`charge()` 中通过 `vipCoin.burn(account, TOKEN_ID_COIN, amount)` 扣减）。因此攻击者拿不到可消费的 API 额度。
- 在合约内部，`TOKEN_ID_VIP = 3` 仅在 `CardShop.sol:98` 被用来判断“该账户是否已有 VIP（每个账户仅一个）”，以及 `makeCard` 内被铸造。`appRegistry.addUser(to)` 也不会赋予任何特殊权限。
- 因此链上层面，VIP 代币只是一个会员标记 NFT，没有折扣、没有额度、没有其他特权。攻击者“白嫖”到的只是这个 NFT 本身；其真实价值完全取决于**链下/产品侧**是否对持有该 NFT 的用户发放会员权益（如折扣、更高配额、专属功能）。若链下据此发放权益，则是业务层受损；纯链上无资金可直接到手。

### 2. `totalCharged` 膨胀 —— 主要是计费 DoS，而非攻击者获利

- `totalCharged` 为 `uint256`，Solidity 0.8.x 默认开启溢出检查。若直接传入 `MAX_UINT` 且 `totalCharged > 0`，`totalCharged += totalPrice` 会溢出并导致本次调用回滚，调用反而失败。
- 原文 PoC 的巧妙之处在于传入 `MAX_UINT - totalCharged`（而非直接 `MAX_UINT`），于是 `totalCharged + (MAX_UINT - totalCharged) = MAX_UINT`，可稳定将 `totalCharged` 拉满（需先读取公开的 `totalCharged` 值）。
- 拉满后，任何 `charge()` → `_charge()` 中的 `totalCharged += amount` 都会溢出回滚，导致**计费功能永久停滞（DoS）**，直到合约升级。这是典型的“破坏/骚扰（griefing）”影响，伤害的是协议与正常用户，而非让攻击者钱包变厚。
- 注意：`makeCard(attacker, 0, 0, max)`（PoC 第二段原文写法）中 `amount=0`，不会铸造代币，仅膨胀 `totalCharged`，不构成给自己发币，同样只是 DoS。

### 3. 真正能“偷钱”的路径只对 owner 有效

- `takeProfit` / `takeProfitAsEth`（`App.sol:59-76`）受 `totalCharged` 约束：`totalTakenProfit + amount <= totalCharged`。若 `totalCharged` 被膨胀到极大值，拥有 `TAKE_PROFIT_ROLE` 的角色便可以赎回远超实际存入量的 `appCoin`，从而**抽干 ERC4626 金库资产**。
- 但该角色在生产部署中授予的是 owner（`App.sol:34`），并非任意外部攻击者。因此这条资金损失路径的受益者是 owner，攻击者无法借此直接获利（除非攻击者本身就是该角色持有者，而生产环境并非如此）。

### 综合判定

| 影响项 | 攻击者能否直接受益 | 说明 |
| --- | --- | --- |
| 免费铸造 VIP 会员 NFT | 仅链下权益可能受益 | 链上无额度/特权；价值取决于产品侧是否认该 NFT |
| 免费铸造可消费 API 额度（`TOKEN_ID_COIN`） | 否 | 受 `tokenId > TOKEN_ID_AIRDROP` 限制，无法铸造 |
| 直接提走金库资金 | 否 | `takeProfit` 需要 `TAKE_PROFIT_ROLE` |
| 膨胀 `totalCharged` 导致计费 DoS | 否（属于破坏行为） | 伤害协议与用户，不增加攻击者资产 |
| 协助 owner 超额抽走金库 | 仅 owner 受益 | 攻击者需持有 `TAKE_PROFIT_ROLE`，生产环境不满足 |

**一句话总结：** 该漏洞对随机攻击者的“直接财务回报”很低（拿不到可花额度、拿不到钱），主要风险是①白嫖 VIP 身份（若链下认可）与②让计费系统宕机（DoS）。但需警惕：它同时也为 `TAKE_PROFIT_ROLE` 持有者打开了超额抽干金库的后门，一旦该角色私钥泄露或被攻击者取得，资金损失将非常严重。修复时除加访问控制外，应让 `totalPrice` 由模板与数量计算得出，杜绝外部传入。

---

## 三、VIP 有效期 / 等级分析（针对“链下按有效期+等级判断”的补充）

**结论先行：仅通过直接调用 `App.makeCard(attacker, 3, 1, 0)`，攻击者拿到的是一枚“幽灵 VIP NFT”——链上没有任何有效期（expireAt）与等级记录被写入。能否被链下系统认作“有效 VIP”，完全取决于链下读取的是哪个数据源。**

### 链上有效期到底存在哪里

VIP 的有效期与等级（props/name）**不是存在 `vipCoin` 这个 ERC1155 里**，而是存在 `CardTracker` 合约的 `_vipMap[account]`（`VipInfo`），字段包括 `expireAt`、`props`、`name`（即“等级/套餐”信息）：

```solidity
// contracts/v2/CardTracker.sol:23-40
function applyCard(address from, address to, ICards.Card memory card) external override {
    require(msg.sender == _eventSource, "unauthorised");  // 仅 CardShop 可调用
    require(from == address(0), "not supported");
    VipInfo storage info = _vipMap[to];
    if (info.expireAt < block.timestamp) {
        info.expireAt = block.timestamp + card.duration;
    } else {
        info.expireAt += card.duration;
    }
    ...
    info.props = card.template.props;   // 等级/套餐属性
    info.name  = card.template.name;     // 等级/套餐名称
    emit VipChanged(to, info.expireAt);
}
```

- `expireAt`（有效期）与 `props`/`name`（等级）**只能**经由 `applyCard` 写入。
- `CardShopFactory.create` 中 `tracker.initialize(address(shop))` 把 `_eventSource` 设为 CardShop（`CardShopFactory.sol:29`），且 `applyCard` 有 `require(msg.sender == _eventSource)`。**因此除 CardShop 之外，任何地址（包括 App 本身、攻击者 EOA）都无法调用 `applyCard`。**

### 合法流程 vs 攻击流程对比

| 步骤 | 合法购买（`CardShop.buyWithEth/Asset`） | 攻击直接调用（`App.makeCard`） |
| --- | --- | --- |
| 铸造 `TOKEN_ID_VIP=3` NFT | ✅ `vipCoin.mint` | ✅ `vipCoin.mint`（同样成功） |
| 创建 `Card` 并写入 `cards[]` | ✅ `_callMakeCard` 内创建 | ❌ 无（直接调 App，不经过 CardShop） |
| 调用 `tracker.applyCard` 写入 `expireAt` | ✅ `_callMakeCard` 内调用（`CardShop.sol:103`） | ❌ **未调用** |
| 结果 | NFT + 有效期 + 等级 三者齐全 | 仅 NFT；`expireAt=0`、`props/name` 为空默认值 |

也就是说，`App.makeCard` 的代码（`App.sol:119-129`）**只**做了 `vipCoin.mint` 和 `totalCharged += totalPrice`，从不调用 `tracker.applyCard`。攻击者无法伪造或写入任何有效期/等级到 `CardTracker`。

### 对链下系统的影响（两种情形）

链下“按有效期和等级判断”，那么：

**情形 A（推荐/安全的链下实现）：链下读取 `CardTracker.getVipInfo(user)` 的 `expireAt` 与 `props/name` 做校验**
- 攻击者经直接 `makeCard` 后，`_vipMap[attacker].expireAt == 0 < now` → 校验直接失败。
- 攻击者**拿不到任何有效的 VIP 有效期**，更没有等级信息。此漏洞在“有效期”维度上对链下无影响，攻击者只多了一枚无意义的 NFT。✅

**情形 B（危险的链下实现）：链下以 `vipCoin.balanceOf(user, TOKEN_ID_VIP) > 0` 作为 VIP 判定依据**
- 攻击者确实持有 VIP NFT（amount=1，且无人 burn）→ 被认作 VIP。
- 更糟的是：因为没有经过 `applyCard`，`expireAt` 为 0；若链下把“无 expireAt / expireAt==0”当作“永久有效”或干脆不校验 tracker，则攻击者将获得一枚**永久、无到期、可能也无等级的 VIP** —— 这比合法购买的限时 VIP 危害更大（白嫖 + 无过期）。⚠️

### 结论

- **链上层面，直接 `makeCard` 攻击无法给攻击者任何 VIP 有效期或等级**（有效期/等级只由 CardShop 的 `applyCard` 写入，且 `applyCard` 对调用方强校验）。攻击者最多得到一枚“幽灵 NFT”。
- **链下层面是否中招，取决于链下读取的数据源**：
  - 若链下正确依赖 `CardTracker.getVipInfo(user).expireAt > now` 及 `props`/`name` → 攻击者不被认定为有效 VIP。
  - 若链下仅凭 `vipCoin` 的 NFT 持有量判断 → 攻击者反而可能获得“永久无期限 VIP”，后果比合法用户更严重。

### 建议

1. **链下校验必须**：以 `CardTracker.getVipInfo(user).expireAt > block.timestamp` 作为有效期判定，并据 `props`/`name` 判定等级；**绝不可**仅依据 `vipCoin.balanceOf(user, TOKEN_ID_VIP) > 0`。
2. **合约层应修复 `makeCard` 的访问控制**（仅 `cardShop` 或专用角色可调用），从源头杜绝“幽灵 NFT”被铸造，避免链下系统因实现差异而误判。
3. 即便仅铸造 NFT 无有效期，也建议对 `makeCard` 加权限，使链上状态与链下判断保持一致、最小化攻击面。
