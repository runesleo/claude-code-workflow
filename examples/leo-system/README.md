# Leo System：脱敏后的真实结构

[English](README.en.md) · **中文**

这里不是一个虚构的 `Product / Research` 演示，而是 Leo 当前 AI 工作系统的脱敏版本。

保留下来的是真实结构：

- 九条长期业务线；
- 每个任务一份 SSOT；
- 稳定 Owner 与可替换 Worker；
- 有时效的 claim；
- 仓库单 Writer；
- artifact、validation、writeback、rollback 和 next gate；
- 等待任务通过 trigger 回到前台。

拿掉的是绝对路径、thread UUID、实时任务、账号、仓位、健康记录、客户信息和生产控制面。

## 文件

```text
AGENTS.private.example.md       私人层只保存偏好与事实源入口
business-lines.example.json    Leo 的九条真实业务线拓扑
task.example.json              一份沿用真实约束的合成任务样例
writer-lock.example.json       一次仓库写入的 acquire/release 契约
readout.example.txt            业务线摘要与精确任务读取
```

任务和 readout 内容是合成场景，不是 Leo 当前的实时任务；字段、边界和读写关系则来自现行系统。

## 最小接入

1. 复制私人层到不受 Git 跟踪的位置；
2. 把业务线目录改成自己的工作区；
3. 选择一个真实长期任务，建立一份 task 文件；
4. 让 Agent 先读取业务线摘要，再精确读取该任务；
5. 完成一次变更后留下 artifact 与验证；
6. 通过 Owner writeback 更新 task，再次读取确认已持久化。

如果你只有一个项目，不需要复制九条业务线。如果你没有多模型并发，也不需要 writer lock。

这套示例的重点不是“配置越多越专业”，而是复杂度只在真实问题出现后增加。
