# Agent Tool Runtime Playground 设计文档

## 背景

当前仓库是一个空的 Flutter 项目，目标是先作为学习型项目，验证如何在 Flutter 中构建一套面向 agent 的 tool runtime，后续再将其中成熟的运行时和调试方案迁移到企业应用中。

参考企业项目 `../flutter_mada_travel` 后，可以确认其整体形态并不是单纯的 Flutter 应用，而是一个混合架构：

- Flutter 作为容器层，承载一部分原生页面和 Flutter 页面。
- 业务能力中有相当一部分由 WebView/H5 页面承载。
- Flutter、WebView 和原生能力之间通过 adapter 接口、JsBridge handler、统一路由包装层以及 platform channel 串联。

因此，这个学习项目不应该按“纯 Flutter 页面内工具”的方向设计，而应该优先验证“容器侧统一 tool runtime”这一能力分发模型。

## 目标

第一版项目需要验证以下能力：

1. 用统一结构定义 tools，包括元信息和输入 schema。
2. 通过少量执行器完成 tool 调用分发。
3. 提供开发者调试台，支持手工触发 tools。
4. 保留调用记录，便于观察执行行为和排查问题。
5. 保持 runtime 与 UI 解耦，为后续迁移到企业容器层做准备。

## 非目标

第一版不追求以下内容：

- 不构建完整的聊天式 agent 产品。
- 不接入真实 LLM 或流式响应链路。
- 不直接接入企业项目中的真实 WebView 运行环境。
- 不直接接入真实 native MethodChannel 实现。
- 不复刻 `flutter_mada_travel` 当前的完整 monorepo、flavor、plugin 和历史兼容复杂度。

## 推荐范围

第一版使用单一 Flutter app 仓库实现。

不从一开始就搭建 monorepo 或 Melos workspace。目录结构可以为未来拆包预留边界，但第一版应优先优化学习效率和 runtime 清晰度。

## 架构概览

项目建议采用如下分层：

- `app`
  - 应用入口、路由、主题、顶层依赖装配。
- `core/tool_runtime`
  - tool 定义、schema 模型、registry、executors、调用协调器、日志模型。
- `core/bridge`
  - bridge 抽象层，以及用于模拟 JsBridge 的 mock 实现。
- `features/tool_console`
  - tool 列表、参数输入表单、执行入口、结果展示。
- `features/logs`
  - 调用历史与错误详情查看。
- `features/demo_tools`
  - demo tool 的注册与本地 handler 实现。
- `shared`
  - 通用组件、JSON 展示组件、格式化工具等。

依赖方向必须保持单向：

`features` -> `core` -> bridge 或 executor 实现

UI 层不能直接持有 tool 执行逻辑。UI 只负责准备输入、触发 runtime、展示状态与结果。

## Runtime 核心设计

### ToolSpec

`ToolSpec` 用于描述一个 tool，包含：

- `id`
- `title`
- `description`
- `executorType`
- `inputSchema`
- 可选 `tags`

其中 `executorType` 用于将调用分发到匹配的执行器实现。

### ToolInvocation

`ToolInvocation` 表示一次执行请求，包含：

- `invocationId`
- `toolId`
- `input`
- `createdAt`
- `status`

`status` 第一版至少支持：

- `idle`
- `running`
- `success`
- `failure`

### ToolResult

`ToolResult` 表示执行结果，包含：

- `success`
- `data`
- `errorMessage`
- `durationMs`
- 可选 `debugMeta`

### ToolRegistry

`ToolRegistry` 负责管理当前所有已注册的 tool 定义，支持：

- 注册单个 tool
- 注册一组 tools
- 获取 tool 列表
- 按 id 查找 tool

第一版中 registry 保持为内存级抽象即可。

### ToolExecutor

`ToolExecutor` 是运行时执行契约。

第一版只支持两类执行器：

1. `flutter_action`
   - 直接执行 Dart 或 Flutter 侧 handler。
   - 适用于本地路由动作、配置读取、本地状态修改等能力。
2. `js_bridge_action`
   - 通过 bridge 抽象层执行，模拟 JsBridge 风格的方法调用。
   - 第一版只接 mock gateway，不接真实 WebView bridge。

`native_action` 不属于第一版范围，但 runtime 结构需要为其未来加入预留扩展点，且不应要求改动现有 UI 契约。

### Schema 校验

每个 tool 的输入在执行前都必须经过校验。

第一版只需要支持轻量 schema：

- 字段名
- 字段类型
- 必填或可选
- 默认值
- 字段说明

第一版支持的字段类型：

- `string`
- `number`
- `boolean`
- `json`

如果校验失败，则不得发起执行。UI 需要在提交前展示明确的校验错误。

## Bridge 层设计

之所以需要 bridge 层，是因为目标企业应用不是纯 Flutter，而是依赖 WebView 和 JsBridge 能力模型。

第一版应引入：

- `BridgeGateway`
  - 表示按方法名和结构化参数发起 bridge 调用的抽象能力。
- `MockJsBridgeGateway`
  - 学习项目中的模拟实现。

这个 mock gateway 需要具备以下行为：

- 接收 `method` 和 `params`
- 支持模拟成功和失败
- 返回结构化的 JSON 风格数据
- 在结果中附带调试元数据

这样可以让学习项目在不接真实 WebView 的前提下，依然贴近企业中的 bridge 能力分发模型。

## Demo Tools

第一版包含 5 个 demo tools：

1. `app.get_env`
   - 返回当前 app 环境、平台、构建信息。
   - 执行类型：`flutter_action`
2. `app.open_debug_page`
   - 通过 Flutter 路由打开本地调试页。
   - 执行类型：`flutter_action`
3. `storage.set_value`
   - 写入本地 key/value，用于验证参数输入和结果展示。
   - 执行类型：`flutter_action`
4. `bridge.trace_event`
   - 模拟通过 bridge 分发埋点事件。
   - 执行类型：`js_bridge_action`
5. `bridge.open_webview`
   - 模拟通过 bridge 分发打开 WebView 的能力。
   - 执行类型：`js_bridge_action`

这 5 个 demo 足够覆盖当前要验证的两条核心路径：

- Flutter 本地执行
- bridge 介导执行

## 调试台设计

应用首页应直接作为开发者调试台，而不是业务首页。

主调试台建议包含三个主要区域：

1. Tool List
   - 展示可搜索的 tool 列表
2. Inspector
   - 展示 tool 描述、schema 描述、参数输入表单
3. Result Panel
   - 展示执行状态、耗时、结构化结果、结构化错误

应用还应提供一个调用日志页面。

日志页展示信息包括：

- tool 名称
- 执行状态
- 调用时间
- 耗时
- 输入快照
- 输出快照

这部分之所以重要，是因为它最有可能在后续迁移到企业 app 的 debug page 或内部诊断面板。

## 错误处理

runtime 需要明确区分以下三类错误：

- 执行前的输入校验失败
- 执行过程中的 executor 失败
- 运行时未预期异常

这三类错误都必须：

- 在调试台中清晰展示
- 写入调用日志

第一版不需要支持重试、队列、取消或后台任务执行。

## 状态管理

状态管理应选择适合学习项目、执行链路清晰的轻量方案。

实现上建议用单一、显式的 controller 或 notifier 风格管理：

- 当前选中的 tool
- 当前输入草稿
- 当前执行状态
- 调用历史

runtime 契约本身不能依赖 Flutter widget 层特有的状态对象。UI 状态可以包裹 runtime 状态，但 runtime 本身应保持可在纯 Dart 层测试。

## 测试策略

第一版至少包含以下测试：

- schema 校验单测
- registry 查找单测
- `flutter_action` 执行单测
- `js_bridge_action` 配合 mock gateway 的执行单测

Widget test 在第一版中是可选项。如果要加，优先补一个调试台页面渲染的 smoke test，以及一条最基本的执行流测试。

## 迁移映射

这个学习 runtime 后续迁移到企业项目时，应保持如下映射关系：

- `flutter_action executor`
  - 对应企业项目中的 Flutter 侧 service 或 adapter 接口，例如 `PlatformService`
- `js_bridge_action executor`
  - 对应企业项目中的 WebView 与 JsBridge 能力分发
- `BridgeGateway`
  - 对应真实 WebView controller、bridge handler 或能力包装层
- 调用日志 UI
  - 对应企业 app 中的 debug page 或内部排障面板

因此，这个项目不是企业项目的缩小复刻版，而是一个围绕“能力分发模型”搭建的最小可验证 runtime 沙盒。

## 实现约束

- 第一版保持单 app 结构。
- runtime 代码必须与 Flutter widgets 解耦。
- 先使用 mock bridge 执行。
- 在 runtime 结构未验证前，不引入企业项目中的 flavors、多 package、native plugin 配置等复杂度。

## 已确认的设计结论

第一版以下设计决策已经确定：

- 使用单 Flutter app，而不是 monorepo。
- 在 Flutter 容器内构建统一 tool runtime。
- 第一版支持 `flutter_action` 和 `js_bridge_action`。
- 首页直接作为 debug console。
- 第一版不接入真实 LLM。

## 建议的下一步

在这份设计确认后，下一步应编写实现计划，并至少拆成以下阶段：

1. 项目脚手架与依赖初始化
2. runtime 核心模型与 registry
3. executor 与 bridge 抽象层
4. debug console UI
5. demo tools
6. 测试与验证
