# AI 开发流程

这个流程用于把 Study For Read Phone 拆成足够小、足够明确的任务，让 GPT-5.2 级别的模型也能稳定完成代码，不乱改文件，不越界实现。

## 0. 工作区锁定

- 唯一工作区：`D:\Codex\Study For Read Phone`
- 旧项目只读参考：`D:\Codex\Study for Read`
- 所有任务开始前先读 `AGENTS.md`
- 任何代码任务都必须有任务卡，没有任务卡不写代码

## 1. 文档先行

每个功能进入编码前，必须先具备以下文档：

- `docs/specs/PRD-v2.md`：产品范围和首版目标
- `docs/specs/ARCHITECTURE.md`：工程结构、技术栈、数据流、部署方式
- `docs/specs/API_CONTRACT.md`：后端接口、请求、响应、错误码
- `docs/specs/DATA_MODEL.md`：数据库表、字段、索引、关系
- `docs/specs/MOBILE_LOCAL_DATA.md`：移动端本地数据库、文件存储、同步队列边界
- `docs/specs/WEB_READER_LOCAL_DATA.md`：网页阅读端 IndexedDB、浏览器导入、同步队列边界
- `docs/specs/WEB_ADMIN.md`：后台管理端页面范围、权限边界、禁区字段
- `docs/specs/DEPLOYMENT.md`：单机部署、Docker Compose、Nginx、备份、日志、环境变量边界
- `docs/specs/UI_FLOWS.md`：移动端和网页端关键流程
- `docs/specs/MOBILE_UI_STYLE.md`：移动端视觉、阅读器、点词、段落翻译、Anki 导出交互边界
- `docs/plans/MASTER_IMPLEMENTATION_ROADMAP.md`：M1 到 M10 的总执行顺序、依赖和入口任务卡
- `docs/plans/IMPLEMENTATION_START_GATE.md`：每次写代码前必须通过的开工闸门

如果文档缺失，先补文档，不进入编码。

## 2. 计划拆分层级

实施计划必须按四层拆：

1. Milestone：一个可验收的大阶段，例如“后端认证基础”。
2. Feature：一个可独立测试的功能，例如“用户注册登录”。
3. Task：一次 AI 可以完成的小任务，例如“创建 User 表迁移和实体”。
4. Step：2 到 5 分钟内可完成的一步，例如“写 UserRepositoryTest 的邮箱唯一性测试”。

禁止把“实现认证模块”“搭建 Flutter App”这种大任务直接交给 AI 编码。

## 3. 单任务卡格式

每个 Task 必须写成任务卡，包含：

- 任务编号
- 任务目标
- 允许修改文件
- 禁止修改文件
- 前置阅读文件
- 先写的测试
- 实现步骤
- 验证命令
- 验收标准
- 停止条件

任务卡模板见：

- `docs/ai-process/TASK_CARD_TEMPLATE.md`

## 4. TDD 执行循环

代码任务必须按 Red-Green-Refactor 执行：

1. 写一个失败测试。
2. 运行测试，确认失败原因是功能不存在。
3. 写最小实现。
4. 再运行测试，确认通过。
5. 必要时重构。
6. 再运行测试，确认仍通过。

如果无法写自动测试，必须在任务卡里写清楚人工验收步骤和原因。

## 5. 文件所有权

每个任务只允许修改任务卡列出的文件。

如果实现时发现必须修改额外文件：

1. 停止编码。
2. 在回复中说明原因。
3. 更新任务卡。
4. 得到确认后再继续。

## 6. 防越界策略

每个任务必须明确“不做什么”。例如：

- 做注册接口时，不做登录页面。
- 做词条表时，不做翻译供应商接入。
- 做移动端导入解析时，不做云端书柜。
- 做后台词条管理时，不允许查看用户本地原书内容。

## 7. 验证策略

每个任务至少有一个验证命令：

- 后端：`.\mvnw.cmd test`
- Web：`npm run test` 或 `npm run typecheck`
- Flutter：`flutter test`
- 文档：检查链接、路径、任务编号是否一致

如果本机缺少工具链，必须记录为阻塞，不能声称通过。

## 8. AI 交接格式

每次任务完成后，AI 必须输出：

- 修改了哪些文件
- 没有修改哪些关键文件
- 运行了哪些验证命令
- 验证结果
- 下一张建议任务卡

不允许只说“完成了”。

## 9. 推荐实施顺序

1. 写 PRD-v2。
2. 写架构设计。
3. 写数据模型。
4. 写 API 合同。
5. 写 UI 流程。
6. 写移动端本地数据、Web Reader 本地数据、Web Admin、部署规格。
7. 写 Milestone 1 到 Milestone 10 的计划和任务卡。
8. 写总路线图：`docs/plans/MASTER_IMPLEMENTATION_ROADMAP.md`。
9. 写开工闸门：`docs/plans/IMPLEMENTATION_START_GATE.md`。
10. 通过开工闸门后，先执行 Milestone 0：版本控制安全基线。
11. M0 完成后，按任务卡执行 Milestone 1。
12. 后端基础闭环后，再进入移动端基础。
13. 移动端阅读闭环后，再进入学习闭环。
14. 再进入 Web Admin、Web Reader 和部署。

## 10. 编码开工闸门

每次真正写代码前，必须先通过：

- `docs/plans/IMPLEMENTATION_START_GATE.md`

如果开工闸门任意一项不满足，AI 必须停止，先补文档或任务卡，不能直接编码。

首张建议执行任务卡：

- `docs/plans/M0-F01-T01-git-baseline.md`
