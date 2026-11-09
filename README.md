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
| `docs/WORKFLOW.md` | **本組的開發流程**（spec-driven）。角色、產物、循環、三道人類核准關卡 |
| `docs/templates/` | spec、plan、agent 紀錄的範本，複製後填寫 |
| `docs/specs/` | 系統層 spec 與各 feature 子 spec |
| `docs/plans/` | 各 feature 的技術方案與 task 拆解 |
| `docs/agent-runs/` | 給 agent 的指示、決策摘錄、關卡核准紀錄 |
| `docs/meeting/` | 會議紀錄、客戶訪談紀錄 |
| `docs/ai-log/` | AI 使用紀錄（`project-common` 範本） |

## 規則重點

- **不要**在本 repo 另存 `VISION.md` 副本。起始文件只有 `project-common` 那一份，定案後要改須經三組同意。
- 交付物為 **prototype 與相關文件**；prototype 完成即視為本組完成。
- 完成前不讀取其他組的 repo。
- 引擎與 AI 工具的版本見 `project-common` 的 `docs/VISION.md` 第 10 節，三組必須一致。
- 開工前先讀 `docs/WORKFLOW.md`。重點：**agent 未經人類 review 不得 commit 或 push**，`main` 一律走 PR，spec 與 plan 要經關卡核准 agent 才能往下做。

## 開始前

```bash
git config commit.template .gitmessage
```
