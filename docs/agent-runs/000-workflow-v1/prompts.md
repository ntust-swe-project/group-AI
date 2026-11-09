# 000-workflow-v1 — 給 agent 的指示

**這不是 feature。** 編號 `000` 保留給 repo 的 bootstrap 工作（流程文件本身），feature 從 `001` 起算。

原文照貼，去掉機密資料（`WORKFLOW.md` 第 8 節）。本次指示內無個資與憑證。

---

## 2026-11-09 · 流程設計 · 立項

**工具**：Claude Code 2.1.319 ／ Claude Opus 5
**session**：見 `transcript.md` 的 session 表

```
我們的專案有兩個 repo 分別是 project common 跟 group AI
請先閱讀 project common 以裡面的 vision 為主
幫我們撰寫我們專案進行的 workflow 放在 repo 中
我們打算使用 spec driven 方式來開發

[附上作業要求原文]
• Define your method: roles (agents vs. humans), artifacts, cycle, and the review gates where a
  human must approve before the agent continues.
• Keep the spec, the agent plans and transcripts, and your reviews in the Git repository.
• Rules: humans stay accountable; no agent commits or pushes without human review; no
  confidential data in prompts.

這邊還有一些作業的要求 有需要做決定的地方直接提出
```

---

## 2026-11-09 · 流程設計 · 決策

agent 讀完 `project-common` 後提出四個決策點與推薦方案，組內逐項回答：

```
Q1 Spec 粒度       → 兩層：系統 spec + feature 子 spec（未採用 AI 推薦的「每 feature 三件式」）
Q2 審查關卡        → 3 道（採用 AI 推薦）
Q3 Commit 權限     → 人類核准 diff 後由 agent commit（採用 AI 推薦）
Q4 組員人數        → 2 人
```

---

## 2026-11-09 · 流程設計 · 撰寫

```
目前看起來沒問題 這個 workflow 之後能滾動修改嗎 還是決定就要做到底
```

→ 組內確認流程文件可滾動修改，agent 據此寫入 `WORKFLOW.md` 第 12 節的修訂機制。

---

## 2026-11-09 · 交付 · 走流程

```
根據我們的 workflow 這邊要直接發成 pr 還是直接推
可以 直接開 pr 那關於紀錄的部分你可以順便紀錄嗎
```
