# 000-workflow-v1 — 決策摘錄

不存完整對話。裁切原則見 `WORKFLOW.md` 第 7 節。原始 Claude Code 紀錄留在本機 `~/.claude/projects/` 底下，不進 repo。

| 日期 | session | 步驟 |
| --- | --- | --- |
| 2026-11-09 | `session_012aHBxZrLkpYFB8zjUxj1zq` | 流程設計、撰寫、交付 |

---

## 決定

| # | 決定了什麼 | 誰決定 | 理由 |
| --- | --- | --- | --- |
| D1 | spec 分兩層：`docs/specs/SYSTEM.md` + `docs/specs/features/NNN-*.md` | 人類（未採用 AI 推薦） | AI 推薦每 feature 一組 spec／plan／tasks 三件式，組內選兩層，先有系統層界定邊界與共用概念再往下長 feature |
| D2 | 三道人類核准關卡：spec → plan → 程式碼 merge，tasks 併入 plan 一起看 | 人類（AI 提議，組內同意） | 對上「要什麼／怎麼做／做對了嗎」，又不會每個 feature 多等一次人 |
| D3 | agent 展示 diff → 人類核准 → 才由 agent commit 到 feature branch；merge 一律另一人 PR review | 人類（AI 提議，組內同意） | 符合作業「未經 review 不得 commit 或 push」的字面，又不用人工打 commit message |
| D4 | 本組 2 人，每個 feature 互換 Owner／Reviewer | 人類 | — |
| D5 | 流程文件可滾動修改，但要版本號、修訂紀錄與「為什麼改」，且不追溯已完成的 feature | 人類提問、AI 提方案、組內同意 | 流程怎麼演進本身是報告素材；沒有章法的修改會變成漂移 |
| D6 | v1.0 自己走 §6／§12 的 PR 流程進 `main`，不直接 push | 人類（AI 提議，組內同意） | 文件還沒 merge、嚴格說還沒生效，但破例會永久留在 git log 裡；照自己的規則走等於第一筆遵守紀錄 |

### AI 自行判斷、經組內確認才留下的

這些 AI 做了決定、組內只是說「沒問題」，不是組內主動選的。報告要分清楚這兩種。

| # | AI 的判斷 | 影響 |
| --- | --- | --- |
| C1 | plan 放 `docs/plans/NNN-<slug>-plan.md`，tasks 當 plan 最後一節 | 目錄結構 |
| C2 | 不存完整對話 JSONL，只存裁切後的決策摘錄 + prompts + 關卡紀錄 | 證據保存方式（量太大、雜訊多、容易把機密帶進 repo） |
| C3 | 關卡核准簽在 spec／plan 的 frontmatter，讓 git diff 本身成為證據 | 關卡可稽核性 |
| C4 | branch 命名 `spec/NNN-<slug>`、spike 用 `spike/<slug>` | git 慣例 |
| C5 | 純邏輯寫 GUT 單元測試、手感與 UI 走手動驗收清單 | 測試策略（30 天期程下不要求全面自動化測試） |
| C6 | 本組 code scope 表（`sim`／`colonist`／`crisis`／`construct`／`ui`／`score`） | commit 規範；待 `SYSTEM.md` 定案後可能調整 |

---

## AI 提議但被拒絕

### 1. 每個 feature 一組 spec／plan／tasks 三件式目錄

- **AI 的說法**：接近 GitHub spec-kit 的做法，對 agent 最友善，一個 feature 一條 branch 一個 PR，證據好追。
- **為什麼不採用**：組內要先有系統層 spec 界定邊界與共用概念，否則各 feature 的 spec 會各說各話。改為兩層，plan 另立目錄。
- **標記**：無（流程設計選擇，不是 AI-invented requirement）

### 2. 直接把這批變更推上 `main`（AI 自己先否決的選項）

- **AI 的說法**：流程文件還沒 merge，此刻嚴格說還沒生效，bootstrap 第一筆可以直接推。
- **結論**：AI 自己判斷不採用，建議走 PR，組內同意。
- **標記**：無

---

## 引擎 API 驗證

本次沒有產出任何 Godot 程式碼，無 API 可驗。首次出現會在 feature `001` 的 plan 階段。

| API | AI 給的 | 查證結果 | 處理 |
| --- | --- | --- | --- |
| — | — | — | — |

---

## agent 停下來回報的段落

| 日期 | 在哪一步 | 回報了什麼 | 退回到 |
| --- | --- | --- | --- |
| 2026-11-09 | 撰寫前 | agent 先列出自己要做的六項判斷（上表 C1–C6）與文件骨架，等組內確認才動筆，沒有直接寫完 | 無 |
| 2026-11-09 | 交付前 | agent 指出 GitHub 上 `main` 還沒設 branch protection，§6 的「不直接 push」目前只靠自律；這是組內沒注意到的 | 無（列入待辦） |

## AI 自己找到的錯

| 日期 | 錯在哪 | 怎麼發現 |
| --- | --- | --- |
| 2026-11-09 | `WORKFLOW.md` 內部節次交叉引用有兩處指錯（機密資料寫成第 9 節，實際是第 8 節） | agent 寫完後自己 grep 全文的節次引用對照 |
