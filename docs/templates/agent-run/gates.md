# NNN-<slug> — 關卡核准紀錄

判準見 `WORKFLOW.md` 第 5 節。**核准前要真的讀過產物**，在「看了什麼」寫一句具體的。

---

## Gate 1 — spec 核准

| | |
| --- | --- |
| Reviewer | |
| 日期 | YYYY-MM-DD |
| 結果 | 通過 ／ 不通過（退回 S1） |
| 退回次數 | |

**看了什麼、注意到什麼**：

判準：

- [ ] 每條需求可追溯到 `VISION.md` 或客戶訪談
- [ ] 驗收條件可驗證
- [ ] 明確列出不做什麼
- [ ] `INV` 項目已由人類決定去留，理由進 ai-log
- [ ] 沒有違反 `VISION.md` 第 6 節範圍外清單
- [ ] 開放問題清零或明確延後
- [ ] 沒有越界的數值

---

## Gate 2 — plan 核准

| | |
| --- | --- |
| Reviewer | |
| 日期 | YYYY-MM-DD |
| 結果 | 通過 ／ 不通過（退回 S2 ／ 退回 S1） |
| 退回次數 | |

**看了什麼、注意到什麼**：

判準：

- [ ] plan 沒有引入 spec 沒有的需求
- [ ] 每個 task 有驗收方式，能在一個 session 內做完
- [ ] 每個 task 對應到驗收條件，沒有孤兒 task
- [ ] Godot API 全部標了驗證狀態，無殘留 `unverified`
- [ ] 動到 `project.godot` 共用欄位的改動已單獨標出
- [ ] 測試策略寫清楚

---

## S3 diff 核准紀錄

一個核准 = 一個 commit。

| Task | 日期 | Owner | 核准 ／ 退回 | commit | 備註 |
| --- | --- | --- | --- | --- | --- |
| T1 | | | | `<sha>` | |

---

## Gate 3 — 程式碼 review

| | |
| --- | --- |
| Reviewer | |
| 日期 | YYYY-MM-DD |
| PR | #__ |
| 結果 | approve ／ request changes（退回 S3） |
| 退回次數 | |

判準：

- [ ] diff 只動 tasks 涵蓋的範圍
- [ ] 驗收條件逐條過，證據在 PR
- [ ] 測試跑過，輸出貼在 PR
- [ ] commit message 合規，AI 產出的有 `Co-Authored-By`
- [ ] commit 數量與人類核准次數對得上
- [ ] `ai-log/` 已更新，`API` 與 `INV` 分開
- [ ] `agent-runs/NNN-*/` 三個檔案都有內容
- [ ] 沒有機密資料進 repo
- [ ] 沒有改到 `project-common`

---

## 流程事故

破例、agent 違反禁止事項、branch 廢棄，都記在這裡。**這是報告素材，不是要隱藏的事。**

| 日期 | 發生什麼 | 怎麼處理 |
| --- | --- | --- |
| | | |
