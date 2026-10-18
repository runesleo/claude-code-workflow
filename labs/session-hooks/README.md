# Session Hooks Lab

**中文** · [English](README.en.md)

三个 Claude Code 钩子，解决长期用 Agent 时最常见的三种「会话失控」：标题对不上内容、不知道哪个对话能关、只有你能拍板的事没人提。

> 实验性模块，不是 QuietHarness 的安装前提。只用 Python 3 标准库，不联网、不登录；钩子只往模型上下文里加提示，不会替你改标题、归档对话或关闭待办。

| 钩子 | 事件 | 解决什么 |
|---|---|---|
| [`session_title_nudge.py`](hooks/session_title_nudge.py) | UserPromptSubmit | 主线换了，标题还是第一句话自动生成的那个 |
| [`archive_readiness_nudge.py`](hooks/archive_readiness_nudge.py) | Stop | 对话越堆越多，分不清哪个做完了、哪个还挂着事 |
| [`needs_me_surface.py`](hooks/needs_me_surface.py) | SessionStart + UserPromptSubmit | 脚本和 Agent 写下的「需要你决定」的事，写完就没人看 |

## 先试一次

```bash
cd labs/session-hooks
python3 tests/run.py          # 全部用临时目录，不碰你真实的 Claude Code 状态

# 手动喂一个 Stop 事件，看它会怎么拦
echo '{"last_assistant_message":"改完了，测试通过。"}' \
  | SESSION_HOOKS_LANG=zh python3 hooks/archive_readiness_nudge.py
```

## 安装

```bash
mkdir -p ~/.claude/hooks
cp hooks/*.py ~/.claude/hooks/
cp examples/needs-me.example.md ~/.claude/needs-me.md   # 只装第三个钩子时需要，再改成你自己的内容
```

然后把 [`examples/settings.example.json`](examples/settings.example.json) 里的 `env` 和 `hooks` 合并进 `~/.claude/settings.json`（已有同名事件就把条目追加进去，不要整段覆盖）。三个钩子互相独立，只装其中一个也行。

所有钩子共用一个语言开关：`SESSION_HOOKS_LANG=zh` 或 `en`（默认 `en`）。

---

## 1. 会话标题提醒 `session_title_nudge.py`

**问题。** 一个对话从「看个链接」开始，后来变成改部署脚本，标题却一直停在第一句话。会话列表越长越没法找。在 CLAUDE.md 写一条「主线换了就改标题」是软规则，没人执行。

**做法。** 在第 2 条消息、之后每隔一段时间（默认 60 分钟）最多一次，往模型上下文里加一句：主线若换了，就用会话标题工具改成 2–4 个关键词，多条并行用 ` · ` 分隔，最新的放前面；你手动起的标题先问再改；没换就忽略、不提。改不改由模型判断，钩子本身不改任何东西。

**它怎么知道用哪个工具。** 桌面 App（`CLAUDE_CODE_ENTRYPOINT=claude-desktop`）提示用 `set_session_title(session_id="self")`；手机或网页发起的会话（`CLAUDE_CODE_ENVIRONMENT_KIND=bridge`）不认 `self`，提示先 `get_session()` 拿到本会话 id 再改。普通终端会话没有已知的标题工具，默认不提示，可以用 `TITLE_NUDGE_TOOL_HINT` 自己指定。

| 环境变量 | 默认 | 作用 |
|---|---|---|
| `TITLE_NUDGE_MINUTES` | `60` | 两次提醒的最小间隔（分钟） |
| `TITLE_NUDGE_FIRST` | `2` | 第几条消息开始提醒 |
| `TITLE_NUDGE_TOOL_HINT` | 空 | 自定义「怎么改标题」的说明，设置后在任何会话都会提醒 |
| `TITLE_NUDGE_STATE_DIR` | `~/.local/state/claude-session-hooks/title-nudge` | 每个会话的计数文件，7 天不动自动清掉 |
| `TITLE_NUDGE_DISABLED` | 空 | 设为 `1` 关闭 |

**限制。** 钩子只在你发消息时触发，闲着的对话不会被检查；提醒的是模型，模型可能判断错。

---

## 2. 归档检查 `archive_readiness_nudge.py`

**问题。** 一天开十几个对话，收尾时不知道哪个已经交付、哪个还在等决定、哪个交给了别人。凭标题或最后活跃时间判断经常错：子步骤做完不等于整个对话做完。

**做法。** 每次模型准备结束回复时检查最后一行，必须是下面三种之一，否则用 Stop 钩子的 `block` 让它补上：

```text
归档检查：可以归档（已验收、无遗留）
归档检查：暂不归档（还在等你选方案）
归档检查：待交接（交给 docs 任务，待验证回执）
```

英文写法 `Archive check: ready / not yet / hand off` 同样接受，与语言开关无关。判断依据是整个对话：真实交付、未决的决定、运行中的任务、已有的交接回执。如果宿主在事件里提供了 `background_tasks`，且有任务还在运行，写「可以归档」也会被拦回去。

它只是一行提醒：不归档、不读历史、不看时间或标题、不建调度。

| 环境变量 | 默认 | 作用 |
|---|---|---|
| `SESSION_HOOKS_LANG` | `en` | 提示文案语言 |
| `ARCHIVE_CHECK_DISABLED` | 空 | 设为 `1` 关闭 |

**限制。** 依赖 Stop 事件里的 `last_assistant_message`；宿主没给就直接放行。`stop_hook_active=true` 时不再拦，避免死循环，所以模型第二次仍漏写也会放过。`background_tasks` 不是所有版本都有。它会让每个最终回复多一行字，不想要就别装。

---

## 3. 「需要我决定」清单 `needs_me_surface.py`

**问题。** 很多事 AI 做不了，只能你拍板：批一笔费用、选方向、重新登录某个服务。脚本和 Agent 会把它们写进某个文件，然后谁也不看；或者每个 AI 各记一份，重复提醒。

**做法。** 只认一个 Markdown 清单（默认 `~/.claude/needs-me.md`），每行一件事，只读未勾选的 `- [ ]` 行，注入模型上下文：

```text
[needs-me / candidate coverage] open_count=3; returned_count=3; remaining_new_count=0; event=SessionStart. ...
- [3f1c…] Approve or reject the $20/month upgrade for the staging database. Source: weekly-cost-report
...
```

并要求模型：
- 把本次返回的每一条只归入一类：`AI_SELF_HANDLE`（AI 自己能处理）、`HUMAN_DECISION`（核实后确实要你决定）、`WAIT_TRIGGER`（在等外部条件）、`STALE_OR_DUPLICATE`（过时或重复）；**四类合计必须等于 returned_count**，核实不了的标 `UNKNOWN`，不许挑一条说、其余悄悄丢掉；
- 只把真正要你决定的简短告诉你；AI 能做的先做，完成要有回执；
- 注入模型不等于你已经看到，也不能据此关闭任何一条。勾选只由你（或负责那件事的流程）在文件里完成。

**去重。** 每条按内容算 16 位指纹，`Source:` / `来源：` 之后的部分不算，换个来源不会被当成新事项。同一会话里已注入过的不再重复；`SessionStart` 时把所有仍未勾选的重新给一遍；一次最多 40 条，剩下的用 `remaining_new_count` 标出，下一条消息继续给。

**失败时不装作没事。** 清单不存在：当作还没配置，静默。清单存在但读不了（是符号链接、超过 256 KB、不是 UTF-8）：注入 `SOURCE_UNAVAILABLE; open_count=UNKNOWN`，要求模型不得宣称没有待办。

| 环境变量 | 默认 | 作用 |
|---|---|---|
| `NEEDS_ME_PATH` | `~/.claude/needs-me.md` | 清单文件 |
| `NEEDS_ME_SEEN_DIR` | `~/.local/state/claude-session-hooks/needs-me-seen` | 每个会话的注入记录，7 天不动自动清掉 |
| `NEEDS_ME_MAX_EMIT` | `40` | 每次最多注入几条 |
| `NEEDS_ME_SOURCE_MARKERS` | `来源：\|Source:` | 算指纹时忽略其后内容的标记，用 `\|` 分隔 |
| `SESSION_HOOKS_LANG` | `en` | 提示文案语言 |

清单格式见 [`examples/needs-me.example.md`](examples/needs-me.example.md)。

**限制。** 清单正文会原样进入模型上下文，钩子把它标成「不可信输入」，但别往里放密钥或别人能写的内容。它只在 Claude Code 里有会话时生效，不会在你没开对话时推送提醒；要手机通知，得接你自己的通知渠道。分类结果是模型给的，钩子只能要求「合计对得上」，不能替你验证每一条分对了没有。

## 它不是什么

不是任务系统、提醒服务或归档工具。三个钩子都只做一件事：在对的时机把一条规则放到模型眼前。事实仍以你的文件和任务记录为准。
