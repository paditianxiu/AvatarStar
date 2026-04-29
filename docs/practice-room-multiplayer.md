# 练习房间广播与多人加入实现说明

## 目标

让玩家 A 创建的练习房间可以出现在其他玩家的大厅房间列表中，并允许玩家 B 通过房间列表进入玩家 A 创建的房间，随后跟随房主进入同一张地图。

## 客户端协议结论

### 创建房间

客户端在 lobby 状态发送 `packetId=38`：

```text
byte   38
string roomName
byte   usePassword
string password
int64  levelId
byte   gameType
byte   maxClientNum
int16  spawnTime
byte   joinHalfWay
byte   checkBalance
byte   canBeWatched
byte   hiddenCreateFlag
string hiddenCreateText
byte   enterLimit
```

服务端返回 `packetId=54`：

```text
byte 54
int  resultCode
int  roomUid
byte status
```

客户端会把 `roomUid` 拆分为：

```text
channelToken = roomUid >> 16
roomId       = roomUid & 0xFFFF
```

创建者收到成功结果后，会自动发送 lobby `packetId=3 + channelToken` 请求房间 channel 地址。

### 大厅房间列表

客户端发送 lobby `packetId=36` 请求刷新房间列表。`36` 的响应只表示刷新结果，房间列表本体通过 `packetId=51` 下发。客户端处理 `36` 时会读取 `byte result + string message`；`result != 0` 会走提示逻辑，所以服务端使用 `0` 表示刷新成功，避免空错误框。

`packetId=51` 是大厅房间列表同步，客户端 `sub_9195E0` 会填充 `StateLobby:GetRoomInfo()` 使用的 `RoomInfo` 列表：

```text
byte 51

repeat:
  int32  roomUid
  byte   roomState
  string roomName
  string mapName
  byte   gameType
  string hostName
  byte   usePassword
  byte   maxClientNum
  byte   currentClientNum
  int64  levelId
  byte   joinHalfWay
  byte   checkBalance
  byte   matching
  byte   canBeWatched
  byte   reserved
  string password
  byte   enterLimit

int32 0
```

说明：

- `roomUid` 低 16 位是 `roomId`，高 16 位是 `channelToken`。
- `sub_9195E0` 调用 `sub_5B91D0(..., flags=2, mask=0)`，因此 `packetId=51` 在 `roomUid` 后读取完整 `RoomInfo`，不能额外写 `roomInfoMask`；多写 mask 会让后续字段全部错位并导致客户端断开。
- 之前误用的 `packetId=26` 实际填充的是 `ClientInfo` 列表，不是大厅 `RoomInfo` 列表；继续用它广播房间会导致大厅不渲染并可能弹空错误提示。
- `packetId=38` 的尾部当前实测为 6 字节。第一个字节不能映射为 lobby `Matching`，否则 Lua 房间列表会过滤该房间；服务端只消费该尾部并固定 `Matching=false`，地图名由 `levelId` 解析。

### 进入他人房间

其他玩家从房间列表选择房间后，会拿房间的 `roomUid` 进入相同流程：

1. 发送 lobby `packetId=3 + channelToken`。
2. 服务端返回 channel 地址。
3. 客户端连接 channel。
4. channel 内发送 `packetId=2`：

```text
int    roomId
string password
int    token
byte   capability 可选
```

服务端进入成功后需要发送：

```text
short 16 进入结果 + 房间完整描述
short 19 房间信息同步
short 18 24 个房间成员槽同步
```

注意：实测 channel `packetId=2` 的 `token` 经常为 `0`，不能可靠代表角色 ID。服务端在 lobby `packetId=3` 请求 channel 地址时，按 `channelToken + remoteAddress` 暂存当前角色，channel 进入房间时消费该记录，保证本机双开也能把第二个玩家加入成正确角色。

### 进入地图

房主开始游戏发送 channel `packetId=10`。服务端进入地图流程至少需要下发：

```text
short 100 进入结果
short 102 levelCode + gameType + localUid + mapId
short 103 角色创建
short 105 loading ready
```

其中 `102` 是客户端加载地图的关键包。

## 原始服务端缺口

1. 创建房间只返回创建者 `54`，没有通知其他 lobby 客户端。
2. lobby `36` 只返回刷新结果，没有下发 `51` 房间列表。
3. `ClientHandler.BroadcastRoomListChanged()` 已存在，但 `GameClient` 没有覆盖 `SendRoomListChangedNotificationAsync()`。
4. `PracticeRoomManager.TryEnterRoom()` 只确保房主成员存在，没有把非房主加入者加入房间成员槽。

## 实现方案

### 房间列表

- `PracticeRoomManager` 提供房间快照列表。
- `AvatarStarClientProtocol` 写出 lobby `51` 批量房间列表。
- `GameClient` 在收到 `15` 时只下发 `30` LevelInfo；收到 `36` 时先回 `result=0` 刷新成功，再发 `51`，避免 Lua 地图表尚未初始化时立刻渲染房间列表。
- 主动房间列表广播只推给已经完成 `15 -> 30LobbyLevelList` 初始化的 lobby 客户端，避免刚进 lobby、尚未初始化地图表的客户端提前收到 `51`。
- 大厅 `51` 当前只列出等待中房间，或显式允许 `JoinHalfWay` 的进行中房间；默认不展示已开局且不可中途加入的房间。
- `GameClient.SendRoomListChangedNotificationAsync()` 推送最新 `51`。
- 创建房间、修改房间、离开/删除房间后调用 `BroadcastRoomListChanged()`。

### 多人加入

- channel `packetId=2` 进入房间时带上当前连接的玩家身份。
- `PracticeRoomManager.TryEnterRoom()` 增加加入者参数。
- 非房主玩家按第一个空 slot 分配成员槽。
- 如果已在房间内，保留原 slot 并刷新角色信息。
- 校验密码、房间人数和房间状态。

### 约束

- 只实现当前协议已确认的最小链路，避免引入未验证的匹配、观战、跨频道分页逻辑。
- 房间列表单包最多 8 个房间，符合客户端读取上限。
- 保持现有 channel 进入地图流程，先补齐 lobby 可见性和成员列表同步。

## 本次实现状态

- 已实现 `PracticeRoomManager.ListLobbyRooms()`，可生成 lobby 房间快照。
- 已实现 lobby `packetId=51` 房间列表写包。
- 已让 lobby `packetId=36` 返回 `result=0`，并在刷新成功后继续下发 `51`。
- 已让创建房间成功后广播最新房间列表给其他已连接 lobby 客户端；创建者只收 `54` 创建结果，避免在自动连接 channel 前被额外 `51` 干扰状态。
- 已让 channel `packetId=2` 按当前玩家身份加入成员槽，非房主会分配第一个空 slot。
- 已注册同房间 channel，成员变化会广播 `19/18` 快照。
- 已让房主开始游戏后，把开始游戏和进入地图序列同步给同房间其他 channel。
- 已把 lobby 请求 channel 与 channel 入房做 30 秒临时身份绑定，避免 `token=0` 时第二个客户端被识别成房主或临时角色。
- 已补齐创建房间包尾部消费：隐藏字段只读不映射，避免误把房间标记为 `Matching` 后被大厅过滤。
