# Chat Export Lab

把 Claude Code、Codex、Cursor、Grok Bot 的本地聊天记录导出成 Markdown，一会话一个文件，任何 AI 都能用 grep 或全文检索查到。

> 实验性模块，不是 QuietHarness 的安装前提。只用 Python 3 标准库，只读本地文件，不联网、不登录、不改任何 App 状态。

## 解决什么问题

同时用好几家 AI 时，聊天记录各存各的：Claude Code 是 jsonl，Codex 是 rollout 文件加 SQLite，Cursor 是两个 SQLite 库，Grok Bot 是 App 里的二进制 blob。你在 Claude 里讨论过的东西，Codex 查不到；换一家 AI，上下文就断了。

这个模块只做一件事：把它们统一成同一种 Markdown，放进同一个目录。之后用什么检索都行：`rg`、qmd、Obsidian，或者让 Agent 直接读。

## 先试一次

```bash
cd labs/chat-export

# 1. 只看会导出多少，不写任何文件
python3 scripts/export_all.py --dry-run

# 2. 真正导出到 ~/.local/share/chat-export/<来源>/
python3 scripts/export_all.py

# 3. 查一下
rg -l "上次那个部署问题" ~/.local/share/chat-export
```

重复运行只处理有变化的会话（按文件修改时间和大小记水位），可以放进你自己的定时任务。`--full` 忽略水位全部重导。

## 支持的来源

| 来源 | 读取位置（默认） | 单独运行 |
|---|---|---|
| Claude Code | `~/.claude/projects/*/*.jsonl` | `scripts/export_claude.py` |
| Codex | `~/.codex/thread_history_*.sqlite`，以及 `~/.codex/sessions/**/rollout-*.jsonl` | `scripts/export_codex.py` |
| Cursor | App：`globalStorage/state.vscdb`；CLI：`~/.cursor/chats/*/*/store.db` | `scripts/export_cursor.py` |
| Grok Bot（macOS 桌面 App） | `~/Library/Application Support/Grok Bot/sand-client-persistence/*.blob` | `scripts/export_grok.py` |

本机没有的来源会自动跳过。每个脚本都能用 `--help` 查看参数，路径都可以覆盖，`--dest` 改输出目录。

## 留什么、丢什么

留：你发的消息，和 AI 给你看的文字回复。

丢：系统提示和注入的上下文（`<system-reminder>`、整份 AGENTS.md、环境信息）、思考过程、工具调用与结果、子 Agent 的旁支对话。不丢的话，每个会话都带一份 AGENTS.md，任何关键词一搜就命中全部会话。

导出前会把常见凭证替换成 `<REDACTED_…>`：私钥、`sk-` 开头的 API key、GitHub / AWS / Slack token、Bearer 头、`*_TOKEN=` 这类赋值、超长 base64。这是尽力而为的规则匹配，**不能保证把所有敏感内容都清掉**。导出的目录和文件都只有你本人能读写（0700 / 0600），只适合留在本机，不要提交到仓库，也不要上传。

## 踩过的坑

- **Codex 新版一轮对话会写好几条回复**：先是「我先看看」这类进度，最后才是结论。只取第一条回复，所有结论都会丢。这里保留一轮里的全部回复。新版 Codex 自己的 `thread_history` 库直接记了每轮的提问和最终回答，存在时优先用它；即使 rollout 文件已被清理，结论也还在。
- **同一个 Codex 会话会跨多个 rollout 文件**（继续、恢复对话时）。按会话 id 命名会互相覆盖，所以按 rollout 自己的 id 命名。
- **Grok Bot 的 blob 里，你的消息和它的回复是两种结构**。只解析一种，就只看到半边对话。
- **超过 6 万字符的一轮直接跳过**，通常是贴进去的日志或整份文件，切一半反而误导检索。

## 它不是什么

聊天记录只是线索，不是事实。决定、进展、下一步还是要写回任务卡、文档或仓库才算数；聊天记录和文件对不上时，以文件为准。这个模块让各家 AI 都能翻到「之前聊过什么」，但不替代这一层。

它也不是同步服务、记忆数据库或向量库：没有后台进程，不做语义合并，不往任何 AI 里写东西。

## 测试

```bash
python3 labs/chat-export/tests/run.py
# CHAT_EXPORT_TEST_OK
```

测试只用临时生成的假数据，不读你的真实聊天记录。

## English summary

Exports local Claude Code, Codex, Cursor and Grok Bot (macOS app) chat history to one Markdown file per conversation under `~/.local/share/chat-export/`, so any agent can search past conversations with `rg` or a full-text index. Stdlib-only, read-only, incremental, with best-effort credential redaction. Run `python3 scripts/export_all.py --dry-run` first. Chat logs are retrieval hints, not the source of truth.
