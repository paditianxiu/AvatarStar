# 商城物品系统集成指南

## 概况

本文档说明如何使用新的**服务端商城物品系统**（Server-Side Shop Item System）来管理和销售游戏中的所有物品。

此系统完全支持从客户端Lua脚本发送的商城RPC请求，并返回格式化的商品数据。

---

## 系统架构

### 核心组件

| 文件 | 用途 | 位置 |
|------|------|------|
| **ShopItemDatabase.cs** | 商城物品数据库 - 包含所有216+可售卖物品的定义 | `Resources/ShopItemDatabase.cs` |
| **ShopItemProvider.cs** | 商城物品服务 - 处理查询、分页、价格计算 | `Resources/ShopItemProvider.cs` |
| **GameClient.Rpc.cs** | RPC处理器 - 从客户端接收商城请求 | `GameClient.Rpc.cs` (修改) |
| **GameClient.Inventory.cs** | 背包管理 - 处理物品添加和购买 | `GameClient.Inventory.cs` (已有) |

### 物品类型

商城支持6种物品类型（itemType/t参数）：

```csharp
enum ItemType {
    Skill = 1,           // 技能 (目前不售卖)
    Equipment = 2,       // 装备 (武器、翅膀等)
    Item = 3,            // 物品 (消耗品、材料等) 
    Gesture = 4,         // 姿态/表情
    AvatarCard = 5,      // 角色卡片 (宠物等)
    SkinCard = 6         // 皮肤卡片 (角色皮肤)
}
```

### 货币类型

```csharp
enum CurrencyType {
    Gold = 1,      // 游戏币 (金币)
    Diamond = 2    // 付费货币 (钻石/点券)
}
```

---

## RPC接口

### 1. 获取商城物品列表

#### 请求
```lua
rpc.safecall("shop_item_list", {
    t = 2,          -- 物品类型 (Equipment=2, Item=3, etc.)
    p = 1,          -- 页码 (从1开始)
    pageSize = 12   -- 每页数量 (可选，默认12)
}, callback)
```

#### 响应
```lua
{
    ok = 1,                    -- 成功标志
    t = 2,                     -- 请求的物品类型
    page = 1,                  -- 当前页码
    pages = 5,                 -- 总页数
    items = {                  -- 商品数组
        {
            sid = 20001,                      -- 商品ID (唯一)
            display = "id_datalist_Gun_01",   -- UI显示文本Key (i18n)
            resource = "pistol_01",           -- 资源ID (mesh/model)
            grade = 1,                        -- 品质等级 (1-5)
            type = 2,                         -- 物品类型
            description = "id_datalist_Gun_01_desc",  -- 描述文本Key
            quantity = 1,                     -- 数量 (可堆叠物品>1)
            category = "Weapons",             -- 分类标签
            isLimited = 0,                    -- 是否限售
            price = {                         -- 价格列表
                {
                    priceId = 1,              -- 价格ID
                    currency = 1,             -- 货币类型 (1=金币, 2=钻石)
                    price = 100               -- 价格
                },
                {
                    priceId = 2,
                    currency = 2,
                    price = 50
                }
            }
        },
        -- ... 更多商品
    }
}
```

### 2. 获取新手推荐物品

```lua
rpc.safecall("get_freshman_item_list", {p = 1}, callback)
-- 返回低等级便宜的物品供新手购买
```

### 3. 获取头像卡片列表

```lua
rpc.safecall("shop_avatar_list", {
    p = 1,
    pageSize = 12
}, callback)
-- 返回所有可购买的角色卡片/宠物
```

### 4. 购买商品

```lua
rpc.safecall("shop_buy", {
    buy = "2,20001,0,1"  -- "itemType,sid,priceId,quantity;"
}, callback)
-- 购买SID=20001的商品，使用第1个价格定义，数量1
```

#### 购买响应
```lua
{
    ok = 1   -- 1=购买成功, 0=失败 (可能原因：商品不存在、货币不足等)
}
```

---

## 商品数据库结构

所有商品在 `ShopItemDatabase.cs` 中静态初始化：

### 武器 (ID: 20001-20999)
- 手枪、机枪、弓、匕首、手榴弹等13种武器
- 品质等级: 1-3
- 金币价格: 100-350 / 钻石价格: 500-2000

### 角色皮肤 (ID: 50001-50999)  
- VIP套装 (男/女)
- 主题套装 (春节、情人节、圣诞节、龙年等)
- 品质等级: 2-3
- 金币价格: 3000-5000 / 钻石价格: 300-500

### 消耗品 (ID: 30001-30999)
- 医疗用品: 绷带、心脏修复液、血清、急救箱
- 食物: 饼干、火腿、龙虾大餐
- 工具: 生命探测器、复活券
- 金币价格: 100-2000 / 钻石价格: 50-1000

### 强化材料 (ID: 40001-40999)
- 基础材料: 矿石、合金、钢铁合金
- 宝石: 红宝石、翡翠、蓝宝石 (普通和精致版)
- 特殊: 高级炸药、复合材料
- 数量: 1-10 (可堆叠)

### 装饰品 (ID: 60001-60999)
- 翅膀: 天使、恶魔、丘比特
- 珠宝戒指: 蓝宝石、红宝石、翡翠、钻石
- 公会徽章: 城堡、海盗、独角兽风格

### 宠物/角色卡片 (ID: 70001-70999)
- 飞行宠物: 小鸟、高级鸟
- 龙系宠物: 红龙/绿龙 (多个等级)
- 地面宠物: 战斗犬、鱼、怪物

---

## 代码使用示例

### 获取商品列表

```csharp
// 获取装备类型的第1页商品
var items = ShopItemProvider.GetShopItemList(
    itemType: 2,    // Equipment
    page: 1,
    pageSize: 12
);
// items 是 List<Dictionary<string, object>> 格式，可直接序列化成Lua

// 获取统计信息
int totalCount = ShopItemDatabase.GetShopItemCount(2);  // 装备总数
List<string> categories = ShopItemProvider.GetCategories();  // 所有分类
```

### 获取单个商品

```csharp
var shopItem = ShopItemDatabase.GetShopItem(20001);  // 获取SID=20001的商品
if (shopItem != null) {
    Console.WriteLine($"{shopItem.Display}: {shopItem.Grade}星");
}
```

### 获取价格

```csharp
// 获取单个商品的购买价格
var (found, currency, price) = ShopItemProvider.GetPurchasePrice(20001, priceIndex: 0);
if (found) {
    Console.WriteLine($"Price: {price} {(currency == CurrencyType.Gold ? "金币" : "钻石")}");
}

// 计算总价 (支持批量购买)
var (success, totalPrice) = ShopItemProvider.CalculateTotalPrice(40001, quantity: 5, priceIndex: 1);
// quantity=5, 钻石价格 (priceIndex=1)
```

### 按分类获取商品

```csharp
var weapons = ShopItemProvider.GetShopItemsByCategory("Weapons");
var consumables = ShopItemProvider.GetShopItemsByCategory("Consumables");
```

---

## Lua序列化

从C#返回到Lua客户端时，响应通过 `LuaSerializer.Serialize()` 转换：

```csharp
// C# 侧
List<Dictionary<string, object>> items = ShopItemProvider.GetShopItemList(2, 1, 12);
writer.WriteString(
    "ok = 1\n" +
    "t = 2\n" +  
    "page = 1\n" +
    "pages = 5\n" +
    "items = " + LuaSerializer.Serialize(items)  // 转为Lua table字符串
);
```

```lua
-- Lua 侧接收
if ok == 1 then
    for i, item in ipairs(items) do
        print(item.sid, item.display, item.resource, item.grade)
    end
end
```

---

## 修改和扩展

### 添加新商品

在 `ShopItemDatabase.cs` 中找到相应的 `Initialize*()` 方法：

```csharp
// 在 InitializeWeapons() 中添加
private static void InitializeWeapons()
{
    var weaponData = new[]
    {
        // ... 现有武器 ...
        ("new_gun_01", "id_datalist_NewGun_01", 2, 500, 1000),  // 新增
    };
    
    int sid = 20001;
    foreach (var (resource, display, grade, goldPrice, diamondPrice) in weaponData)
    {
        AddItem(new ShopItem { ... });
    }
}
```

### 修改价格

```csharp
var item = ShopItemDatabase.GetShopItem(20001);
item.Prices[0].Price = 150;  // 更新金币价格
```

### 标记为限售

```csharp
var item = ShopItemDatabase.GetShopItem(50001);
item.IsLimited = true;  // 限售/已下架
// 购买时会被 ShopItemProvider.CanPurchaseItem() 拒绝
```

---

## 集成检查清单

- [x] ShopItemDatabase.cs 创建 (包含216+商品)
- [x] ShopItemProvider.cs 创建 (查询和分页服务)  
- [x] GameClient.Rpc.cs 修改 (RPC处理器更新)
- [x] using 语句更新 (导入Resources命名空间)
- [ ] 编译测试 (需运行 `dotnet build`)
- [ ] 货币验证实现 (shop_buy中的TODO)
- [ ] 客户端Lua脚本验证 (确保显示文本Key i18n)
- [ ] 价格余额检查 (检查playBalance)

---

## 注意事项

### 显示文本 (i18n)

商品使用 `display` 和 `description` 字符串作为i18n Key，客户端Lua脚本会根据这些Key查找本地化文本。例如：

- `"id_datalist_Gun_01"` → 应在客户端i18n表中对应"手枪"
- `"id_datalist_Gun_01_desc"` → 应在客户端i18n表中对应枪的描述

如果Key不存在，客户端会显示Key本身。

### 资源ID  

`resource` 字段应与客户端解包的资源文件一致（来自 `unpacked_scripts/AvatarStar/` 目录）。

### SID范围

- 20001-20999: 武器
- 30001-30999: 消耗品  
- 40001-40999: 材料
- 50001-50999: 皮肤卡片
- 60001-60999: 装饰品
- 70001-70999: 宠物/角色卡片

避免SID冲突 - 在不同类别中使用相同的SID范围。

---

## 后续改进

1. **数据库持久化** - 将商品定义迁移到JSON配置文件，支持运行时修改
2. **动态定价** - 根据时间、库存、玩家等级调整价格
3. **促销活动** - 支持打折、限时商品、秒杀等
4. **库存管理** - 限售商品的库存追踪
5. **推荐系统** - 根据玩家等级、职业智能推荐商品
6. **购买历史** - 记录玩家购买日志用于分析

---

## 相关文件

- 原资源清单: [RESOURCE_INVENTORY.md](../RESOURCE_INVENTORY.md)
- 快速参考: [RESOURCE_QUICK_REFERENCE.md](../RESOURCE_QUICK_REFERENCE.md)  
- 资源清单JSON: [RESOURCE_MANIFEST.json](../RESOURCE_MANIFEST.json)
