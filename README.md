# group-AI

期中專題 — **AI-Agent 組**。

## 共同輸入

共同輸入與共用規則在 [`project-common`](https://github.com/ntust-swe-project/project-common)：

| 檔案 | 說明 |
| --- | --- |
| `docs/VISION.md` | 起始文件。三組唯一的共同輸入 |
| `docs/COMMIT_CONVENTION.md` | commit message 規則，四個 repo 共用 |

## 本 repo

放本組的產出：需求分析、設計文件、UML、會議與客戶訪談紀錄、AI 使用紀錄，以及 prototype 程式碼。

| 檔案／目錄 | 說明 |
| --- | --- |
| `docs/WORKFLOW.md` | **本組的開發流程**（spec-driven）。角色、產物、循環、兩道人類核准關卡 |
| `docs/templates/` | feature 與 agent 紀錄的範本，複製後填寫 |
| `docs/specs/SYSTEM.md` | 系統層 spec：邊界與共用概念 |
| `docs/specs/features/` | 一個 feature 一個檔：spec + plan + tasks + 關卡簽核 |
| `docs/agent-runs/` | 關鍵指示、決策與被拒絕的建議 |
| `docs/meeting/` | 會議紀錄、客戶訪談紀錄 |
| `docs/ai-log/` | AI 使用紀錄（`project-common` 範本） |

## 規則重點

- **不要**在本 repo 另存 `VISION.md` 副本。起始文件只有 `project-common` 那一份，定案後要改須經三組同意。
- 交付物為 **prototype 與相關文件**；prototype 完成即視為本組完成。
- 完成前不讀取其他組的 repo。
- 引擎與 AI 工具的版本見 `project-common` 的 `docs/VISION.md` 第 10 節，三組必須一致。
- 開工前先讀 `docs/WORKFLOW.md`，**一次就夠**。重點：**agent 未經人類 review 不得 commit 或 push**，`main` 一律走 PR、由 Owner 自審後 merge（例外：自己的 ai-log，見 `WORKFLOW.md` §7），spec 與 plan 經 Gate A 核准 agent 才能動工。

## 開始前

```bash
git config commit.template .gitmessage
```
