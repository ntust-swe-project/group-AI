---
feature: NNN-<slug>
title: <feature 名稱>
owner: <組員>
reviewer: <另一位組員>
status: draft          # draft | approved | done
approved-by:           # Gate 1 通過時由 Reviewer 填
approved-at:           # YYYY-MM-DD
vision-refs:           # 本 feature 支撐 VISION.md 的哪幾節，例如 ["3.1", "4.3"]
---

# NNN — <feature 名稱>

## 1. 這個 feature 要解決什麼

一到兩段。玩家會感受到什麼？對應 `VISION.md` 的哪個核心體驗？

## 2. 需求

一條一件事，每條都要能追溯。追不到來源的不要寫在這裡，放第 6 節。

| # | 需求 | 來源 |
| --- | --- | --- |
| R1 | | `VISION.md` §3.1 |
| R2 | | 2026-11-__ 客戶訪談，見 `docs/meeting/____.md` |

## 3. 驗收條件

每條都要可驗證：讀的人要能照著操作並判斷過或不過。主觀形容詞不算驗收條件。

| # | 驗收條件 | 對應需求 | 驗法 |
| --- | --- | --- | --- |
| A1 | | R1 | GUT 單元測試 |
| A2 | | R2 | 手動：開 prototype，照 X 操作，觀察 Y |

## 4. 這個 feature 不做什麼

明確列出來。S3 實作時 agent 會拿這份當邊界。

- 
- 

## 5. 開放問題

Gate 1 前要清零，或明確標「延後到 feature NNN」。**數值一律先進這裡，不要讓 AI 直接填。**

| # | 問題 | 誰能回答 | 狀態 |
| --- | --- | --- | --- |
| Q1 | | 客戶 ／ 組內 | 待答 ／ 已答（答案寫進第 2 節） ／ 延後到 NNN |

## 6. AI 提出、待人類決定

agent 加的、`VISION.md` 與訪談都追不到的東西。一律標 `INV`，去留由人類決定，去留都要寫理由。

| # | AI 提出什麼 | 標記 | 決定 | 理由 |
| --- | --- | --- | --- | --- |
| I1 | | INV ／ INV+DUP | 納入（成為 R_）／ 不納入 | |

## 7. Changelog

spec 核准後每次修改都加一列，並把 `status` 改回 `draft` 重跑 Gate 1（見 `WORKFLOW.md` 11.1）。

| 日期 | 改了什麼 | 為什麼 |
| --- | --- | --- |
| YYYY-MM-DD | 初版 | 立項 |
