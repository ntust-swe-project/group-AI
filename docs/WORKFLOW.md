# AI-Agent 組 開發流程（Spec-Driven Development）

**v1.2 · 2026-11-10** — 可滾動修改，見 §11

## 1. 這份文件

`VISION.md` §10 把 workflow 留給各組自訂。本組的做法一句話：**spec 經人類核准後 agent 才動工，進 `main` 前再經一次人類 review。**

本文件規範本組怎麼工作，不規範做什麼遊戲（那在 `VISION.md` 與各 feature 的 spec）。與 `VISION.md` 衝突時以 `VISION.md` 為準。

**讀這份文件一次就夠。** 之後每個 feature 只需要 feature 範本與 PR 模板裡的檢查表。如果你得回來重讀，是這份寫壞了。

## 2. 原則

1. 人類負全責。「AI 寫的」不是解釋。
2. spec 是唯一真相來源。碼與 spec 不一致時，先決定哪一邊錯。
3. agent 不自行擴張範圍。`VISION.md` 與 spec 沒寫的，只能提出並標記。
4. 每一步留得下證據。對話關掉後，repo 看得出誰決定了什麼。
5. 沒讀過就按核准，等於沒有關卡。
6. **一件事只記一次。** 同一個事實出現在第二個檔案，就是流程出問題。

## 3. 角色

### 人類（2 人）

每個 feature 指定 Owner 與 Reviewer，下個 feature 互換，寫在 feature 檔的 frontmatter。

| 角色 | 做什麼 |
| --- | --- |
| Owner | 立項、寫 spec 與 plan、驅動 agent、核准 diff、開 PR、當天填 ai-log |
| Reviewer | 簽 Gate A、做 Gate B 的 PR review（**按 Approve，不是只留言**）、merge |

**不可自審**：自己當 Owner 的 PR 不自己 approve 或 merge。

### Agent（四職能，可以是同一個 session 的不同階段）

| 職能 | 在哪步 | 輸出 | 禁止 |
| --- | --- | --- | --- |
| Analyst | S1 | spec 草稿 + 開放問題 | 自己回答開放問題、自己定數值 |
| Planner | S1 | plan 與 task 拆解 | 引入 spec 沒有的需求 |
| Implementer | S2 | 程式碼與測試 | 超出 tasks 範圍 |
| Verifier | S2、S3 | S2：diff 審查結論／S3：逐條驗收結果 | 改碼、改驗收條件、讀實作時的對話 |

Analyst／Planner／Implementer 可以是同一個 session 的不同階段。**Verifier 不行** —— 見 §6「審查 agent」。

用的是單一 session 還是 subagent 編排，要在 ai-log 的「啟用的自動化」欄揭露。

### Agent 絕對不做的事

- 不改 `project-common` 的任何檔案（含 `VISION.md`）
- 不改已核准的 feature 檔（要改走 §10.1）
- **未經人類核准 diff 不得 commit**
- 不得 push 到 `main`、不得 merge、不得 force push、不得改寫 git 歷史
- 不讀其他兩組的 repo（`VISION.md` §11.6）
- 不把機密資料寫進 prompt 或 repo（§9）
- 不升引擎版本、不裝額外依賴

## 4. 目錄

```
docs/
├── WORKFLOW.md                    # 本文件
├── specs/
│   ├── SYSTEM.md                  # 系統層：邊界與共用概念
│   └── features/NNN-<slug>.md     # spec + plan + tasks + 兩道關卡簽核，一個 feature 一個檔
├── agent-runs/NNN-<slug>.md       # 關鍵指示 + 決策與被拒絕的建議
├── meeting/                       # 會議與客戶訪談紀錄（VISION §9.4）
├── ai-log/AI_LOG.md               # AI 使用紀錄（project-common 範本）
└── templates/                     # FEATURE_TEMPLATE.md、RUN_TEMPLATE.md
```

編號從 `001` 起，不重用。`000` 是 repo bootstrap 的歷史紀錄，不是 feature。

## 5. 循環

**開工前只讀三份**：`VISION.md` 的相關章節、`SYSTEM.md`、相關的客戶訪談紀錄。

| 步驟 | 誰 | 產出 |
| --- | --- | --- |
| S0 立項 | Owner | 建 feature 檔、開 branch `spec/NNN-<slug>` |
| S1 spec + plan | Analyst／Planner，Owner 改 | feature 檔的 spec／plan／tasks 三段 |
| **Gate A** | Reviewer | 核准才能動工 |
| S2 實作 | Implementer → Verifier | 逐 task：實作 → **Verifier 新 session 審 diff** → 展示 diff ＋審查結論 → Owner 核准 → agent commit → push |
| S3 驗證 | Verifier（新 session） | 逐條驗收結果 + 測試摘要 |
| S4 PR | Owner | 依 PR 模板開 PR，貼上 S3 的驗收結果 |
| **Gate B** | Reviewer | Approve 後 merge |
| S5 收尾 | Owner | 填 ai-log、補 run 檔、feature 檔 `status: done`、刪 branch |

S2 做不下去（plan 有錯、spec 有漏）時**停下來回報**，不要自己改 spec 或 plan 繞過去。

## 6. 兩道關卡

| 關卡 | 誰簽 | 簽在哪 | 檢查表在哪 |
| --- | --- | --- | --- |
| **Gate A**（實作前） | Reviewer | feature 檔的 Gate A 段，commit 進去 | feature 範本裡，6 條 |
| **Gate B**（merge 前） | Reviewer | GitHub PR 的 **Approve** | PR 模板裡，4 條 |

檢查表只住那兩處，本文件不複製 —— 複製就會漂移。

- **沒簽，agent 不准往下。**
- 核准時寫一到三句「看了什麼、注意到什麼」，不要只打勾。
- 不通過要講明退回哪一步（退 S2 ／ 退 S1），在原檔改，不開新檔、不改編號。
- plan 變大時**把 feature 切小**，不是加關卡。

### diff 核准的深度

**「看 diff」= 掃過每個 hunk、對不認得的地方提問，不是逐字精讀。**

| 變更類型 | 人類要看什麼 |
| --- | --- |
| 只有文件（`.md`） | 審查結論 ＋ agent 的摘要或 PR 整理就夠，不逐 hunk 看 |
| 程式碼（`.gd`、`.tscn`、`project.godot`） | 必須掃過每個 hunk，看不懂的要問 |
| 刪除或搬移檔案 | 必須看，不管什麼類型 |

agent 展示 diff 時固定四行，讓人類掃得快：**改了哪些檔／為什麼／風險在哪／`git diff --stat`**。

分級只調整**深度**，不取消核准 —— 每個 commit 前都還是要有人類說「可以」。

### 審查 agent（必要）

**人類 review 之前，先讓 agent 審。** 審查成本從人移到機器。

一條規則，兩個呼叫點：**審查 agent 必須是新 session，只收 feature 檔與 diff，不收實作時的對話** —— 否則它會替自己辯護。

| 呼叫點 | 審什麼 | 輸出 |
| --- | --- | --- |
| S2 每個 task | 這個 diff 有沒有做到該 task、有沒有超出 tasks 範圍 | 三項：不符之處／超範圍的改動／明顯 bug |
| S3 整份 | 對 feature 檔的驗收條件逐條驗 | 逐條過或不過，不過的寫實際行為 |

- 人類**先看審查結論，再按 §6 的分級掃 diff**。
- **不取代人類核准。** 審查 agent 和 Implementer 共用同一個模型，共享盲點：它抓得到「超出範圍」「和驗收條件不符」這類可機械比對的東西，抓不到「兩邊都誤解了 spec」。
- 它的發現被人類否決時，記進 run 檔的決策表 —— 那是「AI 審 AI」誤判率的素材。初期誤判會偏多，那是預期中的。
- 審查 agent 不得改碼。要改就退回 Implementer。
- 這屬於 agent 編排，要在 `ai-log` 的「啟用的自動化」欄揭露（`VISION.md` §10）。

## 7. Git

- branch `spec/NNN-<slug>`；拋棄式實驗用 `spike/<slug>`，不得 merge
- commit 依 `project-common/docs/COMMIT_CONVENTION.md`
- **一次核准 = 一個 commit**
- **merge 用 merge commit，不要 squash** —— squash 會把「一次核准＝一個 commit」壓掉，那是 Gate B 第 3 條的依據
- 不 force push、不 rebase 已 push 的 branch。整理過的歷史不是證據。
- `main` 無法設 branch protection（免費方案的私有 repo，見 §11 的 v1.1），靠人工把關。自我稽核用：

```bash
gh pr list --state merged --json number,title,reviewDecision
```

**本組的 code scope 補充**（`COMMIT_CONVENTION.md` 要求各組自訂並記在自己 repo）：

| scope | 範圍 | | scope | 範圍 |
| --- | --- | --- | --- | --- |
| `spec` | feature 檔與 `SYSTEM.md` | | `crisis` | 危機波次與調壓 |
| `agent-run` | agent 紀錄 | | `construct` | 建造與自動化 |
| `sim` | 時間推進、每日循環 | | `ui` | 介面與回饋 |
| `colonist` | 殖民者狀態與行為 | | `score` | 單場結算 |

## 8. 紀錄

- **run 檔**（`docs/agent-runs/NNN-<slug>.md`）：給 agent 的關鍵指示、決策與**被拒絕的建議**、API 驗證結果、agent 停下來回報的段落。
- **不存完整對話 JSONL** —— 量大、雜訊多、容易把機密帶進 repo。原始紀錄留在本機 `~/.claude/projects/`，run 檔記 session id 以便回溯。
- **ai-log 當天填**，理由欄限一句，詳細留在 run 檔。`API`（過時引擎 API）與 `INV`（AI 自己加的需求）分開統計。
- **非 feature 工作**（流程修訂、repo 雜務）只進 ai-log 一行 + commit message，**不開 run 檔**。
- **文件預算**：feature 檔 ≤ 150 行、run 檔 ≤ 80 行、PR 內文 ≤ 25 行。超了是流程出問題，不是寫得認真。

## 9. 機密資料

禁止進入 prompt，也禁止進入 repo：

- 真人識別資料：學號、電話、email、私人帳號
- 帳號密碼、API key、token、學校系統登入資訊
- 其他兩組的 repo 內容與未公開產出
- 未公開的課程文件與評分資料

訪談紀錄用角色稱呼（「客戶」、「組員 A」）。送進 AI 工具等同送到外部服務，刪了也可能留存。

不小心貼進去：ai-log 記一筆 → 該段對話不入 repo → 是憑證就立刻換掉。

## 10. 例外

1. **改已核准的 feature 檔**：changelog 加一列（改什麼、為什麼）→ `status` 回 `draft` → 重跑 Gate A。已 merge 的碼不追溯重寫，除非動到驗收條件。
2. **一人不在**：關卡可延後，不可跳過，不可自審。破例要在 feature 檔寫明原因。
3. **agent 跑飛**：branch 廢棄不 merge，run 檔記原因。這是報告素材，不是丟臉的事。
4. **spike**：branch `spike/<slug>`，不寫 spec、不得 merge。學到的寫回 spec 再重走流程。

## 11. 修訂

本文件**兩人同意即可改**（`VISION.md` 要三組同意）。改法：開 PR（branch `docs/workflow-vN`）→ 另一人 approve → commit 用 `docs(repo)` → 下表加一列**寫為什麼**。改了不追溯已完成的 feature。措辭小修 `+0.1`，結構變動 `+1.0`。

| 版本 | 日期 | 改了什麼 | 為什麼 |
| --- | --- | --- | --- |
| v1.0 | 2026-11-09 | 初版：三道關卡、兩層 spec、人類核准 diff 後由 agent commit、agent 紀錄裁切規則 | 依 `VISION.md` §10 建立本組 workflow |
| v1.1 | 2026-11-09 | 記錄 §6 的例外：`main` 無法設 branch protection，改由人工把關 | 免費方案的私有 repo 不支援 ruleset（API 回 403）。PR #1 就在沒有 approve 的情況下被 merge |
| v1.2 | 2026-11-10 | 關卡 3 道→2 道；五個檔併成兩個；檢查表改為單一來源；加文件預算、PR 模板、merge 不 squash、自我稽核命令、diff 核准深度分級、審查 agent | 量測結果：`docs/` 已累積 25,226 字，GDScript 與 spec 各 0 份。原因有三 —— 同一事實被記 4–6 次、固定成本與 feature 大小無關、雜務也開 run 檔。作業要求的四項紀錄一條沒少，砍掉的是重複與儀式。另外人類逐行讀 diff 在文件變更上成本不成比例，改為按變更類型分級，並要求**人類 review 前先由新 session 的審查 agent 審一遍**（把成本從人移到機器，Verifier 的獨立性因此成為硬規則而非建議）——這是**改規則，不是改紀錄**，`000-workflow-v1/gates.md` 的事故列保持原樣 |
