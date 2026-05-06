# Implementation Start Gate

本文件是每次真正写代码前的硬性开工闸门。只要有一项不满足，就停止并先修计划或询问用户。

## 1. 工作区检查

- [ ] 当前要修改的项目是 `D:\Codex\Study For Read Phone`。
- [ ] 旧项目 `D:\Codex\Study for Read` 只作为只读参考。
- [ ] 已读取 `D:\Codex\Study For Read Phone\AGENTS.md`。
- [ ] 本次不会在项目外创建、移动、删除、重命名文件。
- [ ] 本次不会批量删除文件或目录。
- [ ] 如果本次不是 M0，`D:\Codex\Study For Read Phone` 已经是 Git 仓库，且 `git status --short` 可运行。

失败处理：

- 如果当前目录是旧项目，切换到新项目目录后再继续。
- 如果需要删除多个文件，停止，让用户手动处理。
- 如果还不是 Git 仓库，先执行 `docs/plans/M0-F01-T01-git-baseline.md`，不要直接进入业务代码任务。

## 1.1 工具链检查

如果当前任务会运行后端、Flutter、Nuxt、Docker 或数据库命令，必须先确认对应工具链真实可用。

后端 M1 任务必须先运行：

```powershell
cd "D:\Codex\Study For Read Phone"
java -version
$env:JAVA_HOME
where.exe java
```

通过条件：

- `java -version` 必须显示 Java 25。
- `$env:JAVA_HOME` 为空时必须确认 `where.exe java` 指向 JDK 25；非空时必须指向 JDK 25。
- 如果 active Java 是 8、11、17、21 或其他版本，停止并先执行 `docs/plans/M1-F00-T01-backend-toolchain-preflight.md`，不能直接创建 `server`。

失败处理：

- 如果工具链缺失或版本不符，停止并报告阻塞。
- 不允许为了绕过阻塞而把任务卡、规格文档或项目版本降级。
- 如确实需要改技术基线，必须先修改 `ARCHITECTURE.md`、当前 Milestone 计划和相关任务卡，并得到用户确认。

## 2. 文档检查

- [ ] 已读取 `docs/ai-process/AI_DEVELOPMENT_PROCESS.md`。
- [ ] 已读取 `docs/plans/MASTER_IMPLEMENTATION_ROADMAP.md`。
- [ ] 已读取当前 Milestone 计划文件。
- [ ] 已读取当前 Task 任务卡。
- [ ] 已读取任务卡 `Read First` 中列出的规格文档。

失败处理：

- 如果文档缺失，先补文档。
- 如果规格文档和任务卡冲突，先改任务卡或规格文档，不写代码。

## 3. 任务卡完整性检查

当前任务卡必须包含：

- [ ] Task ID
- [ ] Title
- [ ] Goal
- [ ] Scope：本任务只做什么
- [ ] Scope：本任务不做什么
- [ ] Allowed Files
- [ ] Forbidden Files
- [ ] Read First
- [ ] Tests First
- [ ] Implementation Steps
- [ ] Verification Commands
- [ ] Acceptance Criteria
- [ ] Stop Conditions
- [ ] Completion Report Format

失败处理：

- 如果缺任何部分，先补任务卡。
- 如果任务卡范围太大，拆成更小任务卡。

## 4. 文件边界检查

- [ ] 本次只会修改 `Allowed Files` 中列出的文件。
- [ ] `Forbidden Files` 中没有任何本次要修改的文件。
- [ ] 如果要创建新文件，新文件路径已经写入 `Allowed Files`。
- [ ] 如果要引入依赖，依赖名称、版本、原因和被修改的依赖文件已经写入任务卡。
- [ ] 如果要改数据库迁移，迁移文件命名、表名、字段、索引、约束已经和 `DATA_MODEL.md` 对齐。

失败处理：

- 如果必须修改额外文件，停止，更新任务卡，得到确认后再继续。
- 如果依赖没有写入任务卡，停止，先补任务卡。

## 5. 测试优先检查

- [ ] 任务卡已经写明先创建或修改哪些测试。
- [ ] 任务卡已经写明第一次运行测试的命令。
- [ ] 任务卡已经写明预期失败原因。
- [ ] 任务卡已经写明最终验证命令。
- [ ] 如果不能自动测试，任务卡已经写明人工验收步骤和不能自动测试的原因。

失败处理：

- 如果没有测试或验收步骤，先补任务卡。
- 如果本机缺少 JDK、Flutter、Node、Docker 等工具链，停止并报告阻塞，不能假装通过。

## 6. 合规边界检查

任何任务都不能引入以下能力，除非未来有单独规格和用户明确确认：

- [ ] 不上传用户原书文件。
- [ ] 不上传解析后的完整章节。
- [ ] 不在服务端保存原书全文。
- [ ] 不在服务端保存原始段落翻译文本。
- [ ] 不把用户私有整句变成公共词条。
- [ ] 不让后台查看用户原书、章节、原始翻译文本或私密句子。
- [ ] 不实现云端书柜。
- [ ] 不实现支付、订阅、额度闭环。
- [ ] 不实现全书翻译。

失败处理：

- 如果当前任务需要以上能力，停止。这已经超出首版边界，需要先重写 PRD、数据模型和 API 合同。

## 7. 开工判定

只有当 1 到 6 节全部通过，才允许开始当前任务卡的编码。

开工时必须在回复中说明：

- 当前执行的任务卡 ID。
- 本次允许修改的文件。
- 本次禁止修改的关键文件。
- 本次先运行或先编写的测试。
- 本次最终验证命令。

完成时必须按任务卡的 `Completion Report Format` 汇报，不能只说“完成了”。

## 8. 首张建议任务卡

如果当前准备从零开始实现，首张任务卡应为：

- `docs/plans/M0-F01-T01-git-baseline.md`

进入该任务前，再次确认：

- 只初始化 Git 安全基线。
- 不创建 `server` 项目骨架。
- 不实现认证业务。
- 不实现数据库表。
- 不实现移动端、Web Reader、Web Admin。
- 不修改旧项目。
