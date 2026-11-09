# 000-workflow-v1 — 關卡核准紀錄

**本次不適用 Gate 1／2／3。** 那三道關卡是給 feature 的（`WORKFLOW.md` 第 5 節）；流程文件自己的關卡是第 12 節定的「PR + 另一人 approve」。

---

## §12 關卡 — 流程文件修訂

| | |
| --- | --- |
| 版本 | v1.0 |
| 提出者 | <Owner> |
| Reviewer | <另一位組員> |
| branch | `docs/workflow-v1` |
| PR | #__ |
| 日期 | 2026-11-09 開 PR ／ ____-__-__ approve |
| 結果 | 待 review |

判準（§12）：

- [ ] Reviewer 讀過 `WORKFLOW.md` 全文，不是只看摘要
- [ ] 三條作業硬規則都能在文件裡指出位置（人類負責、未 review 不得 commit／push、機密資料禁入 prompt）
- [ ] 四個組內決定（兩層 spec、3 道關卡、commit 權限、2 人分工）寫的和討論一致
- [ ] `transcript.md` 的 C1–C6（AI 自行判斷項）逐條同意
- [ ] 範本可用：照 `SPEC_TEMPLATE.md` 想像得出 feature `001` 怎麼填
- [ ] 修訂紀錄表有 v1.0 一列且寫了為什麼

**看了什麼、注意到什麼**：

（Reviewer 填，不要只蓋章）

---

## commit 核准紀錄

依 §4 的 S3 規則，一次核准 = 一個 commit。

| 內容 | 日期 | 核准人 | 核准 ／ 退回 | commit |
| --- | --- | --- | --- | --- |
| `WORKFLOW.md` + `docs/templates/` + README | 2026-11-09 | <Owner> | 核准（以摘要核准，未逐行看 diff） | `<sha>` |
| `docs/ai-log/AI_LOG.md` | 2026-11-09 | <Owner> | 核准 | `<sha>` |
| `docs/agent-runs/000-workflow-v1/` | 2026-11-09 | <Owner> | 核准 | `<sha>` |
| `project.godot` 進版控 | 2026-11-09 | <Owner> | 核准 | `<sha>` |

---

## 流程事故

| 日期 | 發生什麼 | 怎麼處理 |
| --- | --- | --- |
| 2026-11-09 | Owner 以 agent 提供的摘要核准 commit，未逐行看 diff。§4 S3 要求的是讀 diff | 記錄在此。實際 diff 由 Reviewer 在 PR 上完整檢視，等於把這次的 diff review 併到 §12 關卡 |
| 2026-11-09 | GitHub 上 `main` 尚未設 branch protection，§6 的「不直接 push、一律經 PR」目前只靠自律 | 列為 PR 合併前待辦：在 repo settings 加 ruleset（require PR + 1 approval）。設定完成後在此註記日期 |
