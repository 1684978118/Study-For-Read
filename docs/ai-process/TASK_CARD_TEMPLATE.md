# Task Card Template

复制本模板到 `docs/plans/` 下，为每个小任务创建独立任务卡。

## Task ID

`M1-F01-T01`

## Title

用一句话描述本任务，例如：创建用户表迁移和 User 实体。

## Goal

本任务完成后，系统获得什么最小能力。

## Scope

本任务只做：

- 

本任务不做：

- 

## Allowed Files

本任务允许创建或修改：

- `exact/path/file`

## Forbidden Files

本任务禁止修改：

- `exact/path/file`
- 当前任务未列出的所有业务文件

## Read First

编码前必须先读：

- `AGENTS.md`
- `docs/ai-process/AI_DEVELOPMENT_PROCESS.md`
- `docs/plans/MASTER_IMPLEMENTATION_ROADMAP.md`
- `docs/plans/IMPLEMENTATION_START_GATE.md`
- `docs/specs/ARCHITECTURE.md`
- `docs/specs/DATA_MODEL.md`
- `docs/specs/MOBILE_UI_STYLE.md`（仅移动端 UI 任务需要）

## Tests First

先创建或修改测试：

- `exact/test/path`

测试必须覆盖：

- 

先运行：

```powershell
command here
```

期望结果：

- 测试失败，失败原因是目标功能尚未实现。

## Implementation Steps

- [ ] Step 1: 读取前置文件，确认命名和路径。
- [ ] Step 2: 写失败测试。
- [ ] Step 3: 运行测试并确认失败原因。
- [ ] Step 4: 写最小实现。
- [ ] Step 5: 运行测试并确认通过。
- [ ] Step 6: 如有必要，只在允许文件内重构。
- [ ] Step 7: 再运行验证命令。

## Verification Commands

```powershell
command here
```

## Acceptance Criteria

- 

## Stop Conditions

遇到以下情况必须停止并询问用户：

- 需要修改 Allowed Files 之外的文件。
- 测试失败原因不是当前功能缺失。
- 本机缺少必要工具链。
- 文档、真实代码、计划之间出现冲突。
- 需要批量删除文件或目录。

## Completion Report Format

完成后回复：

- 修改文件：
- 验证命令：
- 验证结果：
- 未完成或阻塞：
- 下一步建议：
