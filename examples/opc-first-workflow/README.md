# OPC 首条业务闭环（离线实验）

**中文** · [English](README.en.md)

使用明确标注的虚构机会样本，确定性地生成研究简报与待审内容，并复用现有 OPC 验收器。无需联网、API Key、模型调用或真实账号，不发布内容。事实和草稿由样本预设；来源引用及文件完整性检查不等于语义事实核验。

从仓库根目录运行：

```bash
python3 examples/opc-first-workflow/run.py --out "$(mktemp -d)/opc-output"
python3 examples/opc-first-workflow/test.py
```

输出目录必须尚不存在。生成六个文件：研究简报、内容草稿、决策记录、产物哈希清单、合成任务记录及验收回执。正常运行须退出 0 并输出 OPC_FIRST_WORKFLOW_PASS，测试须输出 FIRST_WORKFLOW_FOCUSED_TESTS_OK。

失败时可能留有本地诊断文件，以成功退出码和标记为准，不以单个任务文件判定成功。准备任务完成不意味着已获发布授权。Worker 接力、语义交接、Attention Inbox 集成与真实 Agent 运行属于后续增量。
