# localAgent 与 Flutter 流式 Tool 协议设计文档

## 背景

当前存在两个相关方向：

- `localAgent`
  - 负责 AI 侧会话组织、tool 选择与调用决策。
- `learn-agent-flutter`
  - 负责 Flutter 容器内的 tool runtime、bridge 抽象、调试台与本地能力验证。

如果直接在任一仓库内先写实现，再反推交互边界，很容易把某一侧的内部结构误当成协议本身。因此第一版应先定义一份独立的跨仓协议草案，再由 `localAgent` 和 Flutter 两边分别对接实现。

这份文档当前落在 Flutter 仓库中，仅作为协议草案的承载位置，不表示该协议由 Flutter 单边拥有。

## 目标

第一版协议只解决以下问题：

1. 让 `localAgent` 能向 Flutter 发起一次结构化的 tool 调用请求。
2. 让 Flutter 能以流式事件的方式回传调用生命周期状态。
3. 让 tool 成功结果与失败结果都有统一的数据结构。
4. 让协议能直接映射到当前 Flutter 仓库内已有的 `ToolRegistry`、校验器、执行器和日志体系。
5. 为后续接入真实 bridge、真实传输层和多任务并发保留扩展空间。

## 非目标

第一版不解决以下问题：

- 不支持多会话并发。
- 不支持同一会话内多个 tool 并发执行。
- 不定义真实网络传输协议，例如 WebSocket 握手、重连、鉴权。
- 不定义 OpenAI、MCP 或其他外部协议的完全兼容层。
- 不定义复杂 UI 协议，例如 Widget 树差量更新、布局描述、渲染指令。
- 不定义真实企业容器中的 native bridge 细节。

## 第一版范围

第一版协议范围固定为：

- AI 会话类协议
- 流式事件调用模型
- 单会话单任务
- 一次调用只允许一个活跃 `call_id`

也就是说，同一个 `session_id` 下，只存在一个按顺序推进的 tool 调用生命周期：

`requested -> started -> progress* -> completed | failed`

## 总体设计

协议分为两层：

1. 事件层
   - 负责会话归属、顺序、事件类型、时间线推进。
2. 载荷层
   - 负责具体业务数据，例如 assistant message、tool call、tool result。

这种分层的目的很明确：

- `localAgent` 可以稳定地产生事件流，而不直接耦合 Flutter 内部 runtime 类结构。
- Flutter 可以把事件解析为内部调用对象，而不要求对端理解其具体执行器实现。
- 后续如果传输层从本地 mock 切到 WebSocket 或 bridge，也不需要推翻事件与载荷模型。

## 事件信封

所有协议消息都必须遵守统一事件信封。

建议字段如下：

- `event_id`
- `session_id`
- `sequence`
- `type`
- `timestamp`
- `payload`

字段说明如下：

- `event_id`
  - 当前事件的唯一标识。
- `session_id`
  - 当前 AI 会话的唯一标识。
- `sequence`
  - 当前会话内严格递增的顺序号。
- `type`
  - 当前事件的语义类型。
- `timestamp`
  - 事件生成时间，使用 ISO 8601 UTC 字符串。
- `payload`
  - 与 `type` 对应的业务载荷。

示例：

```json
{
  "event_id": "evt_001",
  "session_id": "sess_001",
  "sequence": 1,
  "type": "tool.call.requested",
  "timestamp": "2026-07-02T12:00:00Z",
  "payload": {}
}
```

## 事件类型

第一版固定支持以下 6 类事件：

1. `assistant.message`
2. `tool.call.requested`
3. `tool.call.started`
4. `tool.call.progress`
5. `tool.call.completed`
6. `tool.call.failed`

设计原则如下：

- `assistant.message`
  - 用于承载普通 AI 文本回复，可出现在 tool 调用前后。
- `tool.call.requested`
  - 表示 AI 已决定发起某个 tool 调用。
- `tool.call.started`
  - 表示 Flutter 已接受该调用，并开始进入执行阶段。
- `tool.call.progress`
  - 表示调用过程中产生中间状态、进度、阶段信息。
- `tool.call.completed`
  - 表示调用成功结束，并附带成功结果。
- `tool.call.failed`
  - 表示调用失败结束，并附带结构化错误。

## 时序约束

第一版时序必须保持严格收敛，不允许自由组合。

合法时序如下：

1. `assistant.message` 可选
2. `tool.call.requested`
3. `tool.call.started`
4. `tool.call.progress` 零次或多次
5. `tool.call.completed` 或 `tool.call.failed`

约束如下：

- 同一 `session_id` 下同时只能存在一个活跃 `call_id`。
- `sequence` 在同一 `session_id` 内必须严格递增，不允许乱序或重复。
- `tool.call.completed` 与 `tool.call.failed` 互斥，且必须终结一次调用。
- `tool.call.progress` 只能出现在 `tool.call.started` 之后、终结事件之前。
- 未出现 `tool.call.requested` 时，不得直接发送 `started`、`progress`、`completed` 或 `failed`。
- 如果 session 当前已有活跃调用，则不得接收新的 `tool.call.requested`。

## 载荷定义

第一版定义三类核心载荷：

- `assistant_message`
- `tool_call`
- `tool_result`

### assistant_message

建议结构：

- `message_id`
- `role`
- `content`

约束如下：

- `role` 第一版固定为 `assistant`
- `content` 为字符串，不支持复杂富文本段落结构

示例：

```json
{
  "message_id": "msg_001",
  "role": "assistant",
  "content": "我将为你打开调试页。"
}
```

### tool_call

建议结构：

- `call_id`
- `tool_name`
- `arguments`
- `idempotency_key`

字段说明如下：

- `call_id`
  - 一次 tool 调用生命周期的唯一标识。
- `tool_name`
  - 目标 tool 名称，对应 Flutter 侧 registry 中的已注册 tool。
- `arguments`
  - 结构化输入对象。
- `idempotency_key`
  - 用于后续扩展重复请求判重；第一版可以透传但不强制实现去重。

示例：

```json
{
  "call_id": "call_001",
  "tool_name": "app.open_debug_page",
  "arguments": {
    "source": "agent"
  },
  "idempotency_key": "idem_001"
}
```

### tool_result

建议结构：

- `call_id`
- `status`
- `output`
- `error`

约束如下：

- `status` 只允许 `success` 或 `failed`
- 成功时：
  - `status = success`
  - `output` 必须存在
  - `error = null`
- 失败时：
  - `status = failed`
  - `output = null`
  - `error` 必须存在

成功示例：

```json
{
  "call_id": "call_001",
  "status": "success",
  "output": {
    "route": "/debug"
  },
  "error": null
}
```

失败示例：

```json
{
  "call_id": "call_001",
  "status": "failed",
  "output": null,
  "error": {
    "code": "tool_not_found",
    "message": "Tool app.open_debug_page_x is not registered.",
    "retryable": false,
    "details": {}
  }
}
```

## 错误模型

失败结果不能只返回字符串，必须使用结构化错误对象。

错误结构如下：

- `code`
- `message`
- `retryable`
- `details`

字段说明如下：

- `code`
  - 稳定错误码，供程序判断。
- `message`
  - 面向开发者阅读的错误描述。
- `retryable`
  - 是否建议上层重试。
- `details`
  - 预留调试扩展字段，承载额外上下文。

第一版错误码固定为以下 4 类：

1. `tool_not_found`
2. `invalid_arguments`
3. `execution_failed`
4. `session_state_invalid`

错误分类意图如下：

- `tool_not_found`
  - tool 名称在 Flutter registry 中不存在。
- `invalid_arguments`
  - 参数缺失、类型不匹配、校验失败。
- `execution_failed`
  - tool 已进入执行，但执行器内部失败。
- `session_state_invalid`
  - 事件顺序不合法，或会话中已有活跃调用。

## Flutter 侧落地映射

当前 Flutter 仓库已有如下基础边界：

- `ToolRegistry`
- 输入校验器
- `ToolRuntime`
- `flutter_action` / `js_bridge_action` 执行器
- 调用日志存储

协议第一版建议在 Flutter 侧新增 3 个映射单元：

### ProtocolEventParser

职责：

- 把统一事件信封解析为内部协议对象。
- 解析 `assistant.message`、`tool_call`、`tool_result` 载荷。
- 对 `type` 与 `payload` 的对应关系做基础校验。

### SessionOrchestrator

职责：

- 维护单会话单任务状态机。
- 校验事件时序是否合法。
- 拒绝非法并发调用。
- 将合法 `tool_call` 转发给现有 `ToolRuntime`。

### ProtocolEventEmitter

职责：

- 在 Flutter 内部执行开始时发出 `tool.call.started`
- 在执行过程中发出 `tool.call.progress`
- 在执行完成时发出 `tool.call.completed`
- 在执行失败时发出 `tool.call.failed`

映射关系如下：

- `tool_name` -> `ToolRegistry` 查找
- `arguments` -> 输入 schema 校验
- `tool_call` -> `ToolRuntime` 执行
- `progress` / `result` / `error` -> 协议事件与日志记录

## localAgent 侧职责

协议第一版对 `localAgent` 的要求保持最小化：

1. 生成合法的 `session_id`
2. 生成严格递增的 `sequence`
3. 在需要调用 Flutter tool 时发送 `tool.call.requested`
4. 接收 Flutter 回传的 `started`、`progress`、`completed`、`failed`
5. 按 `call_id` 将返回事件关联到当前会话上下文

第一版不要求 `localAgent`：

- 管理多会话并发调度
- 承担复杂的断线重放逻辑
- 支持一次消息内多 tool 编排

## 调试与回放要求

虽然第一版不定义完整回放协议，但必须为调试保留基本能力。

最小要求如下：

- 每个事件都可写入本地日志
- 每个事件都能按 `session_id + sequence` 还原顺序
- 每次 `tool_call` 都能从 `requested` 追踪到终结事件

这部分是后续扩展“会话回放”和“trace 查询”的前提，因此第一版不能省略 `session_id`、`sequence`、`call_id` 这三个字段。

## 后续扩展点

如果第一版顺利验证，后续扩展顺序建议如下：

1. 单会话多任务并发
2. 多会话并发
3. 真实传输层，例如 WebSocket
4. 真实 bridge / native 容器对接
5. UI/页面/设备能力类更丰富的 tool 协议
6. 协议共享目录或独立仓库存放

## 设计结论

第一版协议采用“统一事件信封 + `tool_call` / `tool_result` 载荷”的双层结构。

它的关键取舍是：

- 优先固定时序与错误语义，而不是一开始追求并发能力。
- 优先与 Flutter 现有 runtime 边界对齐，而不是提前兼容复杂外部协议。
- 优先让 `localAgent` 与 Flutter 之间能稳定跑通一条流式主链路，而不是过早扩到完整 agent orchestration。

只要这版协议先站稳，后续无论真实运行在 Flutter 调试台、企业容器、WebView bridge 还是本地 mock 传输层，演进成本都会明显低于“先写实现再补协议”。
