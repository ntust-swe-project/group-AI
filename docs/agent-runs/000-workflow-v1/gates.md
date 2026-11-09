# 000-workflow-v1 — 關卡核准紀錄

本檔是 workflow v1.0／v1.1 時期的紀錄，當時一個 run 分三個檔。v2.0 起改為一個 feature 一個 run 檔（`WORKFLOW.md` §4），本目錄保留不動。

**本次不適用 Gate 1／2／3。** 那三道關卡是給 feature 的（`WORKFLOW.md` 第 5 節）；流程文件自己的關卡是第 12 節定的「PR + 另一人 approve」。

---

## §12 關卡 — 流程文件修訂

| | |
| --- | --- |
| 版本 | v1.0 |
| 提出者 | 組員 A（Owner） |
| Reviewer | 組員 B |
| branch | `docs/workflow-v1` |
| PR | [#1](https://github.com/ntust-swe-project/group-AI/pull/1) |
| 日期 | 2026-11-09 開 PR ／ 2026-11-09 merge（GitHub 上未留 approve，見流程事故第 3 列） |
| 結果 | 已 merge；Reviewer 意見於 v1.1 事後補記 |

判準（§12）：

- [x] Reviewer 讀過 `WORKFLOW.md` 全文，不是只看摘要
- [x] 三條作業硬規則都能在文件裡指出位置（人類負責、未 review 不得 commit／push、機密資料禁入 prompt）
- [x] 四個組內決定（兩層 spec、3 道關卡、commit 權限、2 人分工）寫的和討論一致
- [x] `transcript.md` 的 C1–C6（AI 自行判斷項）逐條同意
- [x] 範本可用：照 `SPEC_TEMPLATE.md` 想像得出 feature `001` 怎麼填
- [x] 修訂紀錄表有 v1.0 一列且寫了為什麼

**看了什麼、注意到什麼**（2026-11-09 補記）：

1. merge 前讀了 WORKFLOW.md 全文，transcript 和範本是 v1.1 補記時才看
2. 讀完 WORKFLOW 之後，還是不清楚 Reviewer 要在 GitHub 按 approve、要填 `gates.md`：`WORKFLOW.md` §5 和 §12 只寫「approve」，沒寫具體在 GitHub 怎麼操作
3. `transcript.md` 的 C1–C6 有兩處問題，但不影響核准：
   - C1：寫「tasks 是 plan 的最後一節」，但 `PLAN_TEMPLATE.md` 的 Task 拆解（§5）後面還有 Changelog（§6）
   - C5：隱含「邏輯要跟場景分開」的架構要求，但沒有寫進任何文件
4. 同意 merge。`WORKFLOW.md` 沒寫具體的部分，以及 C1、C5 的問題，另開 issue，在 feature 001 建立之前處理

---

## commit 核准紀錄

依 §4 的 S3 規則，一次核准 = 一個 commit。

| 內容 | 日期 | 核准人 | 核准 ／ 退回 | commit |
| --- | --- | --- | --- | --- |
| `WORKFLOW.md` + `docs/templates/` + README | 2026-11-09 | 組員 A | 核准（以摘要核准，未逐行看 diff） | `d56de37` |
| `docs/ai-log/AI_LOG.md` | 2026-11-09 | 組員 A | 核准 | `7e19bb5` |
| `docs/agent-runs/000-workflow-v1/` | 2026-11-09 | 組員 A | 核准 | `28bf7ad` |
| `project.godot` 進版控 | 2026-11-09 | 組員 A | 核准 | `d9cb887` |
| `gates.md` 補上 PR #1 連結 | 2026-11-09 | — | **未核准**（agent 自行 commit，見流程事故第 4 列） | `42ae719` |

---

## 流程事故

| 日期 | 發生什麼 | 怎麼處理 |
| --- | --- | --- |
| 2026-11-09 | Owner 以 agent 提供的摘要核准 commit，未逐行看 diff。§4 S3 要求的是讀 diff | 記錄在此。實際 diff 由 Reviewer 在 PR 上完整檢視，等於把這次的 diff review 併到 §12 關卡。**（v1.1 補記：PR #1 上沒有 review 或留言紀錄，見第 3 列）** |
| 2026-11-09 | GitHub 上 `main` 尚未設 branch protection，§6 的「不直接 push、一律經 PR」目前只靠自律 | 列為 PR 合併前待辦：在 repo settings 加 ruleset（require PR + 1 approval）。設定完成後在此註記日期。**（v1.1 補記：GitHub 免費方案的私有 repo 無法使用 ruleset／branch protection，API 回 403。依 §6 改為人工把關，記於 `WORKFLOW.md` §12 v1.1）** |
| 2026-11-09 | Reviewer 讀過 `WORKFLOW.md` 後直接在 GitHub merge PR #1，沒有留 approve review，也沒有填本檔 §12 紀錄。原因：Reviewer 不清楚自己在關卡要做的具體動作 | 以 PR `docs/workflow-v1.1` 補記 Reviewer 意見、commit sha 與本列。「Reviewer 具體要做哪些動作」是否寫進 `WORKFLOW.md` §5，提交組內討論 |
| 2026-11-09 | agent 在開完 PR #1 之後自行追加 `42ae719`（把 PR 連結補進本檔），沒有先展示 diff 給 Owner 核准。違反 §2.3 與 §4 S2 的「未經人類核准 diff 不得 commit」 | 2026-11-10 由組員 A 於 PR #2 的 approve 中確認未核准，於 workflow v2.0 修正本檔核准紀錄。commit 不改寫，保留在歷史裡 |
