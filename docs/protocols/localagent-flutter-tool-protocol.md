# localAgent Flutter Tool Protocol

## Status

- Status: Draft v1
- Owner: Shared contract between `localAgent` and Flutter consumers
- Current hosting repo: `learn-agent-flutter`
- Scope: Single-session, single-active-tool-call, streaming tool lifecycle events

这份文档是正式对接入口，用于后续 `localAgent`、Flutter 容器、其他 agent 工具或桥接服务进行协议对齐。

它不同于 `docs/superpowers/specs` 和 `docs/superpowers/plans`：

- `docs/protocols/`
  - 面向跨仓 consumer 的正式协议文档
- `docs/superpowers/specs/`
  - 面向当前仓库开发过程的设计文档
- `docs/superpowers/plans/`
  - 面向当前仓库开发过程的实现计划

## Goal

本协议用于定义 `localAgent -> Flutter` 的 tool 调用主链路，使调用方和执行方可以在不共享内部实现细节的情况下，对齐以下能力：

1. 发起结构化 tool 调用请求
2. 接收流式生命周期事件
3. 接收统一的成功结果与失败结果
4. 保证单会话内严格顺序和单任务约束

## Non-Goals

本协议第一版不覆盖以下能力：

- 多会话并发
- 单会话多 tool 并发
- 真实传输层协议，如 WebSocket 握手、重连、鉴权
- 复杂 UI 渲染协议
- OpenAI / MCP 全量兼容层
- 原生 bridge 的底层实现细节

## Version 1 Scope

第一版范围固定为：

- AI 会话类协议
- 流式事件模型
- 单会话单任务
- 单次调用只允许一个活跃 `call_id`

合法生命周期如下：

`tool.call.requested -> tool.call.started -> tool.call.progress* -> tool.call.completed | tool.call.failed`

## Envelope

所有事件都必须采用统一信封结构：

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

字段定义：

- `event_id`
  - 当前事件唯一标识
- `session_id`
  - 当前会话唯一标识
- `sequence`
  - 当前会话内严格递增的顺序号
- `type`
  - 事件类型
- `timestamp`
  - ISO 8601 UTC 时间字符串
- `payload`
  - 与 `type` 匹配的业务载荷

## Event Types

第一版固定支持以下事件：

- `assistant.message`
- `tool.call.requested`
- `tool.call.started`
- `tool.call.progress`
- `tool.call.completed`
- `tool.call.failed`

语义如下：

- `assistant.message`
  - AI 的普通文本消息
- `tool.call.requested`
  - AI 发起 tool 调用请求
- `tool.call.started`
  - Flutter 已接受调用并开始执行
- `tool.call.progress`
  - Flutter 执行中间态或进度事件
- `tool.call.completed`
  - Flutter 执行成功结束
- `tool.call.failed`
  - Flutter 执行失败结束

## Ordering Rules

第一版必须遵守以下时序约束：

- 同一 `session_id` 下同时只能存在一个活跃 `call_id`
- `sequence` 在同一 `session_id` 内必须严格递增
- `tool.call.progress` 只能出现在 `tool.call.started` 之后
- `tool.call.completed` 和 `tool.call.failed` 互斥，且必须终结一次调用
- 未收到 `tool.call.requested` 时，不得直接发送 `started`、`progress`、`completed` 或 `failed`
- 如果当前 session 已有活跃调用，不得接受新的 `tool.call.requested`

## Payloads

第一版定义三类核心 payload：

- `assistant_message`
- `tool_call`
- `tool_result`

### assistant_message

```json
{
  "message_id": "msg_001",
  "role": "assistant",
  "content": "I will open the debug page."
}
```

字段要求：

- `role` 第一版固定为 `assistant`
- `content` 为字符串

### tool_call

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

字段要求：

- `call_id`
  - 一次调用生命周期唯一标识
- `tool_name`
  - 目标 tool 名称
- `arguments`
  - 结构化输入对象
- `idempotency_key`
  - 预留给重复请求判重

### tool_result

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

字段要求：

- `status` 只允许 `success` 或 `failed`
- 成功时：
  - `output` 必须存在
  - `error` 必须为 `null`
- 失败时：
  - `output` 必须为 `null`
  - `error` 必须存在

## Error Model

错误对象结构如下：

```json
{
  "code": "execution_failed",
  "message": "bridgeMethod is missing",
  "retryable": false,
  "details": {}
}
```

字段定义：

- `code`
  - 稳定错误码
- `message`
  - 面向开发者的错误说明
- `retryable`
  - 是否建议重试
- `details`
  - 扩展调试字段

第一版错误码固定为：

- `tool_not_found`
- `invalid_arguments`
- `execution_failed`
- `session_state_invalid`

## Flutter Reference Mapping

当前 Flutter 侧的对应实现入口如下：

- 协议模型
  - [lib/core/protocol/models/protocol_models.dart](/Users/xuewen/ai-lab/project/learn-agent-flutter/lib/core/protocol/models/protocol_models.dart)
- 协议解析器
  - [lib/core/protocol/parser/protocol_event_parser.dart](/Users/xuewen/ai-lab/project/learn-agent-flutter/lib/core/protocol/parser/protocol_event_parser.dart)
- 单会话状态机
  - [lib/core/protocol/session/session_orchestrator.dart](/Users/xuewen/ai-lab/project/learn-agent-flutter/lib/core/protocol/session/session_orchestrator.dart)
- 事件发射器
  - [lib/core/protocol/emitter/protocol_event_emitter.dart](/Users/xuewen/ai-lab/project/learn-agent-flutter/lib/core/protocol/emitter/protocol_event_emitter.dart)
- runtime 执行映射
  - [lib/core/tool_runtime/runtime/tool_runtime.dart](/Users/xuewen/ai-lab/project/learn-agent-flutter/lib/core/tool_runtime/runtime/tool_runtime.dart)
- 调试入口
  - [lib/features/tool_console/tool_console_controller.dart](/Users/xuewen/ai-lab/project/learn-agent-flutter/lib/features/tool_console/tool_console_controller.dart)

## localAgent Integration Guidance

如果你在 `localAgent` 中开发对应调用服务，推荐按以下顺序接入：

1. 先实现统一信封结构：
   - `event_id / session_id / sequence / type / payload`
2. 再实现 `tool.call.requested` 请求构造
3. 再实现 `started / progress / completed / failed` 的事件消费
4. 最后用 Flutter 侧的 `Protocol Demo` 链路做第一条联调基线

第一版 `localAgent` 侧最小职责：

- 生成合法的 `session_id`
- 生成严格递增的 `sequence`
- 构造合法的 `tool_call`
- 消费 Flutter 返回的协议事件
- 按 `call_id` 关联一次调用生命周期

## Canonical Source and Related Docs

当前正式对接入口是本文件。

相关设计与实现过程文档仍然保留，用于仓库内部开发参考：

- 设计文档
  - [docs/superpowers/specs/2026-07-02-localagent-flutter-streaming-tool-protocol-design.md](/Users/xuewen/ai-lab/project/learn-agent-flutter/docs/superpowers/specs/2026-07-02-localagent-flutter-streaming-tool-protocol-design.md)
- 实现计划
  - [docs/superpowers/plans/2026-07-02-localagent-flutter-streaming-tool-protocol.md](/Users/xuewen/ai-lab/project/learn-agent-flutter/docs/superpowers/plans/2026-07-02-localagent-flutter-streaming-tool-protocol.md)

如果后续该协议被多个仓库长期共用，应进一步迁移到共享协议目录或独立仓库，由该位置承担长期的 contract ownership。
