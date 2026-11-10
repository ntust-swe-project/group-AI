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
| 2026-11-10 | Claude Code 2.1.322（CLI） | Claude Opus 5.5 | `superpowers` plugin v7.0.0：SessionStart hook 注入 skill 指引，本次使用其 `receiving-code-review` skill。未啟用自訂 hooks、未啟用 subagent 編排 | 無 |
| 2026-11-10 | Claude Code 2.1.322（CLI） | Claude Opus 5.5 | `superpowers` plugin v7.0.0：SessionStart hook 注入 skill 指引，本次使用其 `brainstorming` skill。**repo 內附** `Donchitos/Claude-Code-Game-Studios` v1.3.0（`abc0de7`）的 agent、skill 與路徑規則（`.claude/rules/`，碰到對應檔案自動載入）；該模板的 18 個 hooks 與狀態列**未啟用**、根目錄 `CLAUDE.md` 未搬。另附 `rockerBOO/gut-skill`（`0259877`，本組改過）。未啟用自訂 hooks、未啟用 subagent 編排；本次用過 `web-fetch` subagent 一次讀網頁 | GUT 9.7.1（Godot 單元測試，非 AI 工具） |
| 2026-11-10 | Claude Code 2.1.312（Claude 桌面版 Code 分頁） | Claude Opus 5.5 | 無 hooks、無 subagent 編排，output style 為 Learning。自 PR #10 起，repo 內附的模板 skill 在處理 `group-AI/` 底下的檔案時可被載入；本列生效時尚未使用任何一個 | 無 |
| 2026-11-10 | Claude Code 2.1.322（CLI） | Claude Opus 5.5 | 同第 4 列，另加 **subagent 編排**：審查 agent 與 S3 Verifier 改用新開的 subagent（repo 內附 Game Studios 的 `qa-tester`），只給 feature 檔與 diff，不給對話；讀網頁用 `web-fetch` subagent。另用 `superpowers` 的 `test-driven-development` skill 與本組 `/gut` skill | GUT 9.7.1 |

補充說明：

- 2026-11-10 起，`VISION.md` 第 10 節提到的 `Donchitos/Claude-Code-Game-Studios` 模板**當工具**放進 repo（PR #10）：agent 與 skill 可用，但它的 hooks 未啟用、它的工作室流程不採用。裝了什麼、哪些不要用見 `docs/TOOLS.md`。repo 內附的工具 pull 下來對兩人都生效，組員 B 開始用時也在上表加一列。
- `.claude/settings.local.json` 目前只關掉一個與本專題無關的 skill，沒有其他自動化設定。
- `WORKFLOW.md` §3 的四個 agent 職能：Analyst／Planner／Implementer 仍是同一個 session 的不同階段；**Verifier（審查 agent 與 S3）自 feature 001 起由組員 A 改為獨立 subagent**，見上表第 6 列。
- 上表各列**並存**，不是替換：第 1、3、4、6 列是組員 A 的環境，第 2、5 列是組員 B 的環境。兩人的工具版本、模型與設定不同，使用紀錄裡由誰的環境產出，看「任務」欄的說明。

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
| 6 | 2026-11-10 | 流程檢討（組員 A 環境） | 請 AI 量測 `docs/` 的文件量與程式碼產出，診斷「寫文件的時間遠大於 AI 工作的時間」 | 接受 | | AI 量出 25,226 字文件／0 行 GDScript／0 份 spec，指出三個成因：同一事實被記 4–6 次、固定成本與 feature 大小無關、雜務也開 run 檔。後兩項是 AI 自己的設計造成，由 AI 主動認列 | 待填 |
| 7 | 2026-11-10 | 流程瘦身（組員 A 環境） | 請 AI 依兩道關卡重寫 `WORKFLOW.md` v1.2、把五個檔併成兩個、寫 PR 模板 | 修正後接受 | | 關卡降兩道由組內決定。AI 原提的「tasks 超過 5 個仍走 3 道」例外被組內否決，改為把 feature 切小。AI 自行刪掉 v1.1 §12 的 AI 揭露表（與本檔重複，違反 v1.2 新增的原則 6）；瘦身後 12,585 字→5,325 字，未達 AI 自訂的 4,000 字目標 | 待填 |
| 8 | 2026-11-10 | 流程瘦身（組員 A 環境） | 組內提出「人類可不可以只看 PR 的整理」，請 AI 判斷 | 接受 | | AI 指出兩個 review 時機不能一起放寬：Gate B 從 PR 整理看起本來就對，但 S2 的逐 task diff 若只讀 agent 自己寫的摘要，等於 agent 替自己打分。提出按變更類型分級（文件看摘要、程式碼必看 hunk、刪檔必看），並建議以新 session 的 agent 當第二雙眼睛但不取代人類核准。兩項都採用 | 待填 |
| 9 | 2026-11-10 | 流程瘦身（組員 A 環境） | 組內認為「給人類 review 前要先給 subagent review」比較妥當，請 AI 改寫 | 修正後接受 | | 組內把 AI 設計的「第二雙眼睛（可選）」改為**必要**。AI 的修正：不另立概念，而是把既有的 Verifier 職能擴到 S2，並把「必須是新 session、不讀實作時的對話」從建議升為硬規則——等於減少一個概念。AI 另主動加註審查 agent 與 Implementer 共用模型、共享盲點，因此不能取代人類核准 | 待填 |
| 10 | 2026-11-10 | 流程瘦身（組員 A 環境） | PR #3 的 Reviewer request changes：`gates.md` 流程事故表的列號引用錯位、版本號應為 v2.0，請 AI 修正 | 修正後接受 | | 兩項都是 AI 的錯且都由人類關卡抓到。① AI 插入 `42ae719` 事故列時沒更新三處「第 N 列」引用；Reviewer 提出的修法（把該列按時間順序移到表尾）比改引用更好，三處引用同時變正確。AI 自查後發現第三處（commit 核准紀錄的「第 4 列」）Reviewer 沒點出但也是錯的，同時修掉。② AI 把結構變動（關卡 3→2、循環 7→5 步、審查 agent 改必要）標成 v1.2，違反自己在 §11 寫的「結構變動 +1.0」 | 待填 |
| 11 | 2026-11-10 | 流程瘦身（組員 A 環境） | 組內定「應該只有 code 要過審」，請 AI 把審查 agent 的適用範圍限縮 | 接受 | | 組員 A 提出、組員 B 在 PR #3 討論後同意，把 #9 定的「一律必要」限縮為「程式碼必要」。理由兩個：① 流程文件與紀錄的 `.md` 多半是人寫的意見，不是 agent 產出；② 全部過審的 token 成本太高。同時議定 spec 另案處理 —— spec 雖然是 `.md`，但由 Analyst agent 起草，改為人類讀全文（§6 分級表加一列、Gate A 檢查表加一條）。AI 在此只負責落地，範圍由組內定 | 待填 |
| 12 | 2026-11-10 | 流程瘦身（組員 A 環境） | PR #3 第二輪 request changes：spec 要由人審全文、#11 理由欄有三處不符實際，請 AI 修正 | 修正後接受 | | AI 在寫自己的使用紀錄時，把決定權與「克制」都歸到自己身上：① 把 #9 組內定的「一律必要」寫成 AI 自己的設計、② 編了一個「承前一筆」的因果、③ 拿 #10 當「AI 自己判斷過審不划算」的證據，而 #10 其實是 AI 寫錯 `.md`、由人抓到，方向相反。三處都由 Reviewer 指出。保留本列而不併進 #11，因為「AI 自述不可靠、要由人核對」本身就是結論。文件修正四處（§6 分級表加 spec 一列、§6 範圍句、Gate A 檢查表加一條、#11 理由欄）由 Reviewer 指定 | 待填 |
| 13 | 2026-11-10 | PR #3 審查第一輪（組員 B 環境） | 請 AI 分析 PR #3 的 diff 找出問題，並依 Reviewer 決定的範圍（列號引用、版本號）起草 Request changes 意見 | 部分接受 | | AI 列出 5 處問題，Reviewer 自行核對後只把列號引用與版本號列為阻擋項，草稿中「修完即可 approve」等 AI 加入的判斷經 Reviewer 確認後未修改即送出 | 0.4h |
| 14 | 2026-11-10 | PR #3 審查第二輪（組員 B 環境） | 請 AI 分析 `a011990` 的範圍與 ai-log #11 理由欄的錯誤，並依組內結論（AI 審程式碼、人審 spec）起草留言 | 接受 | | AI 指出 `a011990` 超出 request changes 範圍與 #11 三處不符實際，原先「拆成另一個 PR」的建議在與組員 A 討論後改為在 PR #3 內修正，留言草稿未修改即送出 | 0.3h |
| 15 | 2026-11-10 | PR #3 複查（組員 B 環境） | 請 AI 複查兩輪修正是否到位，並起草 approve 補記 | 接受 | | AI 確認四處修正與連帶改動到位並指出 approve 意見空白，補記中「看了什麼」由 Reviewer 確認屬實後送出 | 0.2h |
| 16 | 2026-11-10 | PR #4 審查（組員 B 環境） | 請 AI 檢查 PR #4（客戶訪談紀錄 001）並起草重新 approve 的意見 | 部分接受 | | AI 指出「已同步至 project-common」不實（組員 A 另於 `887bd47` 自行修正），但起草時誤以為組員 B 是客戶、經組員 B 更正；最終意見刪去 AI 的觀察與出席欄建議，採用 AI 建議把核對範圍寫成「內容合理，未對照原始問答」 | 0.6h |
| 17 | 2026-11-10 | 系統層 spec 起草（組員 A 環境） | 請 AI 只以 `VISION.md` 與訪談 001 為輸入，起草 `SYSTEM.md` 的邊界、共用概念、系統層約束與待決項，並把組內決定落地 | 修正後接受 | | 待決項全由人決定（S2 客戶裁決，S3–S5 組內）。AI 的錯由人抓到：S5 原敘述把 Q3 已定的「不預警」誤列為待決。`SC1`–`SC9` 是 AI 從訪談推出的推論，交 Reviewer 逐條確認 | 待填 |
| 18 | 2026-11-10 | 系統層 spec 更正（組員 A 環境） | 客戶釐清 Q5 的「兩秒」後，請 AI 更正 `SC4` | 修正後接受 | | 錯在 AI 的推論：「兩秒內看得到反應」等於給實作一筆可用掉的延遲預算。客戶（組員 A 兼任）釐清兩秒是判定卡住的上限，改為「當下就開始執行」（`b97875d`） | 待填 |
| 19 | 2026-11-10 | PR #5 review 修正（組員 A 環境） | 請 AI 讀 Reviewer 的 request changes，依組員 A 的回應修 `SYSTEM.md`、查 `project-common` 有沒有被改過、起草本輪 ai-log | 接受 | | 三點的處理由組員 A 決定：S3 補註類型共通，但不照 Reviewer 建議寫「名稱另取」—— 壓力、體力是通用詞，只避開《缺氧》特有名詞；`SC4`、`SC7` 屬系統層必要機制而保留，S4 的回本公式移交 feature；`project-common` 未被修改。AI 查到本機 `project-common` 自 clone 後無檔案變動、與遠端一致，並指出 PR 內文「agent 改 `project-common`」一句與事實不符 | 待填 |
| 20 | 2026-11-10 | PR #5 審查第一輪（組員 B 環境） | 請 AI 對照 `SYSTEM.md` 全文與 PR #5 內文找出問題，並依 Reviewer 的決定（S1 分離、SC9／五條不做／15 個名稱同意）起草 Request changes 意見 | 接受 | | AI 指出 S3 七條需求有六條與《缺氧》重疊、spec 開頭「不寫機制」與 SC4／SC7／S4 矛盾、agent 改 `project-common` 未記事故；「組內決定」的疑慮因組員 B 確認有參與而撤回，草稿未修改即送出 | 0.4h |
| 21 | 2026-11-10 | PR #5 複查（組員 B 環境） | 請 AI 複查組員 A 的三個新 commit，並起草 approve 意見 | 修正後接受 | | AI 指出 ai-log #19「`project-common` 未被修改」的證據時間窗口晚於事件、並承認自己第一輪建議的「名稱另取」不準確；組員 A 在群組說明 agent 曾開始修改後改寫後續段落，組員 B 再把「你」改為「組員 A」以免旁人看不懂 | 0.7h |
| 22 | 2026-11-10 | workflow v3.0（組員 A 環境） | 請 AI 依組內決定取消 Reviewer 角色，改 `WORKFLOW.md`、PR 模板、feature 範本、README 並開 PR #9 | 接受 | | 範圍由組員 A 決定（Gate A、Gate B 都由 Owner 自簽）。AI 指出 §7 的 `reviewDecision` 稽核命令在自審後一律為空，改成列出所有直接 push 的命令；修改流程本身仍要另一人 approve（§11）是 AI 提議、組員 A 同意保留 | 待填 |
| 23 | 2026-11-10 | AI 工具導入（組員 A 環境） | 請 AI 評估並導入 Game Studios 模板、GUT 與 GUT skill，寫 `docs/TOOLS.md`（PR #10），並把 v2.0 刪掉的 GUT 規則補回 WORKFLOW（PR #11） | 接受 | | 「模板當工具、不採用其流程」與「hooks 先關」由組員 A 決定，依據是 AI 讀過 hook 腳本後的評估：它們會在每個 session 注入模板流程。AI 建議不採用組員 A 找的 game-art skill（只有美術建議、不產生素材），組員 A 同意。AI 發現 GUT skill 寫於 Godot 4.7 之前、double 回傳值已過時，對 GUT 9.7.1 原始碼核對並實測後修正；README「AI 工具三組一致」與 VISION 矛盾，組員 A 指出是 README 早於 VISION 定案 | 待填 |
| 24 | 2026-11-10 | workflow v2.1（組員 B 環境） | 請 AI 依組內決定起草 §7 的 ai-log 例外條款、§11 修訂列與 README（PR #8） | 接受 | | AI 起草例外條款並提出「是否另設對方核對」的補償措施選項，組員 B 選擇各自核對；AI 自行修正同一段兩個「§3」指涉不同的歧義 | 0.5h |
| 25 | 2026-11-10 | PR #9 審查（組員 B 環境） | 請 AI 分析取消 Reviewer 角色的影響，並起草 approve 意見 | 部分接受 | | AI 依 PR #3–#5 的資料建議只保留 Gate A 交叉審查的折衷方案，組內因耗時（流程接近 Waterfall）未採用；approve 草稿未修改即送出 | 0.3h |
| 26 | 2026-11-10 | PR #11 審查（組員 B 環境） | 請 AI 核對補回 GUT 規則是否正確，並起草 approve 意見 | 接受 | | AI 確認 v2.0 之後的 §8 沒有 GUT 規定、原引用為空，並指出這個空引用從 PR #3 就存在，AI 自己在 PR #5 的分析中也沿用了它 | 0.2h |
| 27 | 2026-11-10 | feature 001 立項與 spec（組員 A 環境） | 請 AI 起草雛型骨架的 spec、plan、tasks，數值留給人填 | 修正後接受 | `INV` | 開放問題 Q1–Q6 由組員 A 答（一天 5 分鐘、3 人、0.5×–4× 等）；AI 提的 I1–I5（閒晃、變速、資訊面板、除錯按鈕、目錄）組員 A 全部納入。API 對本機 Godot 4.7.2 的 API dump 核對 | 待填 |
| 28 | 2026-11-10 | GUT 靜默通過修正（組員 A 環境） | 做 T1 時 AI 發現測試檔語法錯誤 GUT 仍回 exit 0，請 AI 修（PR #13） | 修正後接受 | | AI 第一版 hook 掃整個 `test/`，審查 agent 指出會誤判 `-gselect` 篩選過的 run；改版後 9 種情況實測。審查 agent 另建議「只判斷 `null`」，AI 實測後否決（壞腳本 `load()` 不回 null）。AI 起初以「測試工具」為由沒送審，事後補跑 | 待填 |
| 29 | 2026-11-10 | feature 001 實作 T1–T9 與 S3（組員 A 環境） | 請 AI 逐 task 以 TDD 實作，每個 task 交新 subagent 審查後再核准（PR #14） | 修正後接受 | `INV` `API` | 審查 agent 每個 task 都有發現：第 30 天長度為 0（組員 A 改 spec 為走完才結束）、名字用完的處理是 AI 自決（成為 I6）等；兩條被判誤判，記在 run 檔。`API`：AI 寫 `DayClock.new() is Node`，4.7 在 parse 時就擋下。組員 A 看截圖後改為橢圓大廳、以地板面積定大小。流程事故 6 條（含 Gate A 重簽前就改碼）記在 `docs/agent-runs/001-base-skeleton.md` | 待填 |

**結果**：`接受` ／ `修正後接受` ／ `部分接受` ／ `拒絕`

**標記**：`API`（AI 產出過時或不存在的引擎 API）／ `INV`（AI-invented requirement）／ `DUP`（只是在重現參考遊戲的設計）。#1–#26 都在流程文件階段，還沒碰到引擎 API 與遊戲需求，三個標記都空白；從 #27（feature 001）開始才有。

---

## 3. 統計

每個里程碑或每週更新一次。

| 項目 | 數 |
| --- | --- |
| 紀錄筆數 | 29 |
| 接受 ／ 修正後接受 ／ 部分接受 ／ 拒絕 | 13 ／ 12 ／ 4 ／ 0 |
| `API` 筆數 | 1（#29） |
| `INV` 筆數（含 `DUP`） | 2（#27、#29；共 6 項，feature 001 的 I1–I6，全部納入） |
| 累計工時 | ≥ 4.6h（#1–#3、#6–#12、#17–#19、#22–#23、#27–#29 待組員 A 補） |

統計區間：2026-11-09 起（repo 初始化至 PR #14 merge）。

---

## 4. 流程成本觀察

本組方法論的第一個可量化結果，記在這裡是因為過了這個階段就量不回來。

**2026-11-10，workflow v2.0 瘦身前**（repo 開張第 4 天）：

| 項目 | 量 |
| --- | --- |
| `docs/` 總量 | 25,226 字 / 973 行 |
| GDScript | 0 個檔案 |
| scene | 0 個檔案 |
| feature spec ／ plan | 0 ／ 0 份 |

成本分布：`WORKFLOW.md` 50%、記錄「怎麼寫那份流程」的 run 檔 21%、還沒人用過的範本 19%、課程真正要求的 ai-log 10%。

**觀察**：agent 驅動的 spec-driven 把成本從寫程式移到寫規格與留證據。三個成因裡只有第一個是方法論本身的性質（規格要先寫清楚），另兩個是流程設計失誤（同一事實記 4–6 次、雜務也套完整流程）。v2.0 砍掉後兩者，作業要求的四項紀錄一條沒少。

**待觀察**：v2.0 之後跑 feature 001 到 003，比較「文件字數／程式碼行數」的比值會不會收斂。

---

## 填寫原則（摘自範本）

1. **「拒絕」和「修正」的理由最有價值**，報告主要靠這些。接受的可以寫簡略一點。
2. **`API` 和 `INV` 一定要分開**。前者是 Godot 4.7 晚於模型知識截止造成的雜訊，後者才是三組要比較的現象。
3. 工時算實際花在這件事上的時間，**包含 review AI 產出與修正的時間**。
4. 當天沒用 AI 不用補紀錄；但完全沒有紀錄的一段時間，報告裡要能解釋。
5. 客戶訪談的問答紀錄不寫在這裡，依 `VISION.md` 第 9 節第 4 點另存於 `docs/meeting/`。

---
