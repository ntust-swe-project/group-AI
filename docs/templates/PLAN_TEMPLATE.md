---
feature: NNN-<slug>
spec: ../specs/features/NNN-<slug>.md
owner: <組員>
reviewer: <另一位組員>
status: draft          # draft | approved | done
approved-by:           # Gate 2 通過時由 Reviewer 填
approved-at:           # YYYY-MM-DD
---

# NNN — <feature 名稱> 技術方案

輸入只有已核准的 spec。**這份文件不得引入 spec 沒有的需求** —— 需要新需求就回 Gate 1。

## 1. 方案

怎麼做、為什麼這樣做。有考慮過但沒採用的做法也寫一句，連同不採用的理由。

## 2. 要動的檔案

| 檔案 | 新增／修改 | 做什麼 |
| --- | --- | --- |
| | | |

**會動到 `project.godot` 共用欄位嗎？** 否 ／ 是（是的話單獨說明，原則上不准動 —— `VISION.md` 第 10 節） 

## 3. 引擎 API 驗證

用到的 Godot API 逐個列。Gate 2 前不得殘留 `unverified`（`VISION.md` 第 10 節）。

| API | 狀態 | 文件連結 |
| --- | --- | --- |
| | 已驗證 ／ unverified | `https://docs.godotengine.org/en/4.7/...` |

AI 產出的 API 有錯的，在 `docs/ai-log/` 記一筆並標 `API`。

## 4. 測試策略

| 對象 | 怎麼測 |
| --- | --- |
| 純邏輯（狀態轉換、波次推進、計分） | GUT 單元測試 |
| 手感、UI、視覺 | spec 第 3 節的手動驗收清單，由人類操作 |

## 5. Task 拆解

一個 task 一個 commit，對應一次人類核准 diff。每個 task 要能在一個 agent session 內做完。

- [ ] **T1** — <做什麼>
  - 驗收條件：spec A1
  - 做完的判準：
- [ ] **T2** — <做什麼>
  - 驗收條件：spec A2
  - 做完的判準：

每條驗收條件都要有 task 對應，每個 task 都要對應到驗收條件（沒有孤兒 task）。

## 6. Changelog

| 日期 | 改了什麼 | 為什麼 |
| --- | --- | --- |
| YYYY-MM-DD | 初版 | |
