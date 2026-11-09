# AI 使用紀錄 — AI-Agent 組

欄位依 `project-common/docs/AI_LOG_TEMPLATE.md`（`VISION.md` 第 11 節第 5、7 條）。流程上哪一步會產生哪種紀錄，見 `docs/WORKFLOW.md` 第 9 節。

commit 這份文件時用 scope `ai-log`。

---

## 1. 工具揭露

工具、模型或自動化設定有變動時**新增一列**，不要改舊的。

| 生效日 | 主要工具與版本 | 主要模型 | 啟用的自動化 | 其他工具 |
| --- | --- | --- | --- | --- |
| 2026-11-09 | Claude Code 2.1.319 | Claude Opus 5 | `superpowers` plugin v7.0.0（官方 plugin cache）：SessionStart hook 注入 skill 指引、本次使用其 `brainstorming` skill。未啟用自訂 hooks、未啟用 subagent 編排 | 無 |
| 2026-11-09 | Claude Code 2.1.312（Claude 桌面版 Code 分頁） | Claude Opus 5.5 | 無 hooks、無 subagent 編排。output style 設為 Learning（AI 會把部分內容留給人類親自完成，並附解說） | 無 |

補充說明：

- 本組**未**採用 `VISION.md` 第 10 節提到的 `Donchitos/Claude-Code-Game-Studios` 模板，因此沒有該模板的 per-tool-call bash hooks。
- `.claude/settings.local.json` 目前只關掉一個與本專題無關的 skill，沒有其他自動化設定。
- `WORKFLOW.md` 第 2.2 節的四個 agent 職能目前以「同一個 session 的不同階段」實作，不是獨立 subagent。改成 subagent 編排時要在上表新增一列。
- 上表兩列**並存**，不是替換：第 1 列是組員 A 的環境，第 2 列是組員 B 的環境。兩人的工具版本、模型與設定不同，使用紀錄裡由誰的環境產出，看「任務」欄的說明。

---

## 2. 使用紀錄

一筆紀錄一件事。**工時含 review 與修正 AI 產出的時間**，不是只算等回應的時間。

| # | 日期 | 任務 | 問了什麼 | 結果 | 標記 | 理由 | 工時 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 2026-11-09 | 流程設計 | 請 AI 讀 `project-common` 的 `VISION.md`、`COMMIT_CONVENTION.md`、`AI_LOG_TEMPLATE.md`，依作業要求提出 spec-driven workflow 的設計選項 | 部分接受 | | AI 提出的四個決策點（spec 粒度、關卡數、agent commit 權限、人數與 review 分工）連同推薦方案都只當選項看；四項全部由組內決定，其中 spec 粒度與關卡數沒有採用 AI 的推薦（AI 推薦每 feature 三件式＋3 道關卡，組內選兩層 spec＋3 道關卡） | 待填 |
| 2 | 2026-11-09 | 流程設計 | 請 AI 依選定方案撰寫 `docs/WORKFLOW.md` 與 `docs/templates/` | 修正後接受 | | 架構與內容採用。修正：內部節次交叉引用有兩處指錯（機密資料節號 9→8）。另有數項 AI 自行判斷、經組內確認才留下的設計，逐條列在 `docs/agent-runs/000-workflow-v1/transcript.md`（plan 檔案位置、transcript 不存完整 JSONL、branch 命名、GUT＋手動驗收的分界） | 待填 |
| 3 | 2026-11-09 | 流程設計 | 問 AI 這批變更依我們自己的 workflow 該直接 push 還是發 PR | 接受 | | AI 依 `WORKFLOW.md` §6、§12 判斷要走 PR，並主動指出兩件事：v1.0 尚未 merge 所以嚴格說還沒生效的 bootstrap 矛盾、以及 GitHub 上 `main` 其實還沒設 branch protection（規則目前靠自律）。第二點是我們沒注意到的 | 待填 |
| 4 | 2026-11-09 | 流程補記（組員 B 環境） | 請 AI 檢查 PR #1 的審查狀態（用 `gh` 查 review 與 branch protection），並草擬 `gates.md` 的 commit sha、流程事故補記，以及 `WORKFLOW.md` v1.1 修訂列 | 接受 | | AI 列出當時未做到的部分核實，到 GitHub 確認 PR #1 沒有 approve、merge 當時還未確認 `transcript.md` C1-6 | 0.5h |
| 5 | 2026-11-09 | 流程補記（組員 B 環境） | 請 AI 檢查組員 B 寫的 Reviewer 意見（一致性、具體度），並潤飾 ② 的排版與標點 | 修正後接受 | | AI 建議 `gates.md` 看了什麼、注意到什麼第四點設定多久前處理分三個時間，修改為一個時間 | 0.5h |

**結果**：`接受` ／ `修正後接受` ／ `部分接受` ／ `拒絕`

**標記**：`API`（AI 產出過時或不存在的引擎 API）／ `INV`（AI-invented requirement）／ `DUP`（只是在重現參考遊戲的設計）。本批紀錄都在流程文件階段，還沒碰到引擎 API 與遊戲需求，所以三個標記都空白。

---

## 3. 統計

每個里程碑或每週更新一次。

| 項目 | 數 |
| --- | --- |
| 紀錄筆數 | 5 |
| 接受 ／ 修正後接受 ／ 部分接受 ／ 拒絕 | 2 ／ 2 ／ 1 ／ 0 |
| `API` 筆數 | 0 |
| `INV` 筆數（含 `DUP`） | 0 |
| 累計工時 | ≥ 1h（#1–#3 待組員 A 補） |

統計區間：2026-11-09 起（repo 初始化至 workflow v1.1）。

---

## 填寫原則（摘自範本）

1. **「拒絕」和「修正」的理由最有價值**，報告主要靠這些。接受的可以寫簡略一點。
2. **`API` 和 `INV` 一定要分開**。前者是 Godot 4.7 晚於模型知識截止造成的雜訊，後者才是三組要比較的現象。
3. 工時算實際花在這件事上的時間，**包含 review AI 產出與修正的時間**。
4. 當天沒用 AI 不用補紀錄；但完全沒有紀錄的一段時間，報告裡要能解釋。
5. 客戶訪談的問答紀錄不寫在這裡，依 `VISION.md` 第 9 節第 4 點另存於 `docs/meeting/`。
