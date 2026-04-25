# Changelog

## v2.0 — 2026-04（实战 ~50 天后的范式调整）

> 不是"加了多少新规则"，而是**砍掉了一类不工作的规则**，换成事件驱动的硬规则 + Hook 拦截层。

### 新增

#### 🆕 Layer 3: PreToolUse Hook 拦截
v1 是三层架构（auto-loaded rules / on-demand docs / hot data）。v2 加了**第四层 — Hook 拦截**，在 Claude 准备执行 tool 的瞬间硬性注入提醒。

**为什么需要**：前三层都依赖模型主动想起来读规则。但实测中模型经常忘 — "读规则的时机永远晚于需要规则的时机"。Hook 不依赖记性，是动作前打断。

例子：跑 `find ~/Projects` 时自动注入"跨物理位置审计前必读 infra 拓扑"提醒。

#### 🆕 10 条事件驱动的 P0 铁律
取代 v1 的抽象规则。每条都来自真实踩坑事件：

| 铁律 | 触发场景 |
|---|---|
| Memory 召回 | 记忆库建好但长期不用 = 等于没建 |
| 产出前 verify | 引用数字/断言用户行为前不查就脑补 |
| 写入前查 SSOT | 同一信息双写到 5 个位置 |
| 完成前 verify | "应该没问题" 没跑测试就 claim 完成 |
| Session-end 必走 skill | 离开信号被忽视，跨 session 待办丢失 |
| P0 必须贴 tool 证据 | 流程作弊（脑内自检后直接打 ✅） |
| 惯性红旗词 | "我一直这么做" = 暂停信号 |
| 文件输出路径 | 无脑 `-d ~/Desktop` 导致桌面堆积 |
| 跨语言禁直译 | 中↔英直译 = 母语用户感到 AI 味 |
| URL 抓取走路由表 | 收到 URL 跳过映射表直接 WebFetch |

**v1 → v2 关键差异**：v1 写"质量控制规则"是抽象描述，v2 每条都标注**触发日期 + 真实事件**。事件让规则可解释、可演化、可裁剪。

> domain-specific 铁律（跨物理位置审计 / 长期任务初始化时序 / 特定环境变量加载顺序等）属于个人配置层，不入此模板。同样定位的 separate plugin repos 留待未来发布。

#### 🆕 4 门过滤器 — 开源更新触发机制
新增章节：开源 repo 不做"日历驱动"更新，必须**触发驱动**。每个候选触发必须过 4 门：① 源于自用迭代或经评估的外部反馈 ② 顺手值得更新 ③ 值得分享给别人 ④ 值得发一条推文。缺一不更新。

避免 repo 维护成本无限堆积、避免"为更新而更新"。

#### 🆕 强制 Subagent 分派清单
v1 写"简单任务建议分派给 Sonnet/Haiku agent"。30 天实测：

| 模型 | 消费占比 |
|---|---|
| 主线程 Opus | 99.8% |
| Agent 调用 | 0.18%（44 次 / 24,722 API calls） |

**抽象原则无约束力，具体触发清单才有**。v2 改成：

| 触发条件 | 必须分派到 |
|---|---|
| Read ≥3 文件才能回答 | Explore agent |
| 跨目录 Grep 多轮 | Explore agent |
| URL 研究 / GitHub repo 调研 | Explore agent |
| >5 文件改动的代码实现 | Implement agent |
| ≥50 行非敏感代码生成 | Implement agent |

每次分派强制输出 `🔀 分派 ...` 留痕，方便审计漏派。

#### 🆕 复杂任务工作流（Plan Gating + Research → Plan → Build）
v1 没有这一层。v2 加了：

- **Plan Gating**：>5 文件改动强制先写 `plan.md`，confirm 后才动代码
- **Research → Plan → Build 三阶段**：复杂任务串联（先 memory_search/Grep/WebSearch 收集，再 plan.md，再 build）
- **Plan 归档**：完成后归档到 `docs/plans/YYYY-MM-DD-{slug}.md` 作为未来 Research 的输入源
- **Worktree 隔离**：Agent 默认 `isolation: "worktree"`，避免并行任务污染
- **Multi-Agent Review**：>50 行改动 Codex + Claude 双轨审查
- **Compound Loop**：>50 行改动后主动自问"有没有可沉淀的模式"，写 patterns.md

#### 🆕 docs/ 新增文件
- `url-routing.md` — URL 抓取按数据源分流到对应工具（替代盲目 WebFetch）
- `daily-workflow.md` — 每日启动流程

### 改写

#### Task Routing 简化
**v1**：Sonnet 评估升级 → Opus / Haiku / Codex / Local 五层分派。
**v2**：精简成两条主线 — Claude 车道（统一 Opus，分析与重要决策）/ Codex 车道（代码实现与交叉验证）+ 阶段级模型切换。

**原因**：实测三层分派几乎不触发，分派开销 > 收益。模型切换粒度从"任务级"调整到"阶段级"（同一阶段内保持单一模型，避免 KV 缓存频繁失效）。

#### Codex 交叉验证强制范围扩展
**v1**：关键代码可选 review。
**v2**：涉及金钱/不可逆操作/核心业务逻辑的代码 → 全部 P0 强制 codex review，附 reasoning effort 档位（high/xhigh）。

#### Self-Improvement Loop 加 Gate 机制
**v1**：被纠正 → 直接 `memory_add`。
**v2**：写入前 3 问 Gate：
1. 是否与现有规则冲突？
2. 是否可验证（有触发条件 + 预期行为）？
3. 3 个 session 后还会被触发吗？

回答"否"→ 标 `⚠️ 待验证` 而非直接写入。
**过期清理**：连续 5 个 session 未触发的 pattern → 标过时清理。
避免 patterns.md 膨胀为垃圾场。

#### Context 管理触发条件改写
**v1**：每 50 轮提醒 `/clear`。
**v2**：触发条件从"轮次"改为"话题切换"。

**原因**：实测同话题持续对话 = 增量缓存命中，跨 session 重建反而贵 5x。

#### 完成验证 + 内容防护
合并 v1 的 "Quality Control + AI Content Safety" 和 "Real-time Experience Recording"，新增：
- 引用任何数字/声明前必须 verify 源头（晋升 P0）
- 涉及外部 URL/他人观点 → 必须标注来源
- "Would a staff engineer approve this?" 自检

### 砍掉

v1 这些规则实测不工作或被新规则覆盖，v2 移除：

- ~~`Tier 1: Sonnet Evaluates Escalation`~~ — 三层路由实测不触发，废弃
- ~~`Browser/Puppeteer Conflicts`~~ — 合并到 `docs/url-routing.md`
- ~~`Project Context Auto-detection`~~ — 合并到 Context 管理
- ~~`Post-compression Re-anchor (On-demand)`~~ — 合并到 Context 管理
- ~~抽象的"建议分派给 agent"~~ — 改成"触发=必须"清单

### 学到的元规则

整个 v2 的迭代过程留下三条元规则，比任何具体规则都重要：

1. **抽象原则无约束力，具体触发条件才有** — "应该 verify"是空话，"看到 URL → 走 url-routing.md → 用首选 CLI"是规则。
2. **规则需要审计层** — 写规则的同时必须建审计机制（execution-log / 周日 skill-audit），否则等于自言自语。
3. **事件比道理更有说服力** — 每条铁律标注真实触发事件，未来才能判断"还要不要保留"。

---

## v1.0 — 2026-03-03

初始 release。三层架构（auto-loaded rules / on-demand docs / hot data）+ 5 个核心 skills + 3 个 agents。

详情见 [git log](https://github.com/runesleo/claude-code-workflow/commits/main)。
