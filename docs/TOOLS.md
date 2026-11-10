# AI 工具與測試環境

repo 裡附帶的 Claude Code 工具，pull 下來就能用。**它們是工具，不是流程** —— 怎麼工作仍以 `WORKFLOW.md` 為準，兩者衝突時聽 `WORKFLOW.md`。

## 1. 裝了什麼

| 東西 | 版本 | 位置 | 授權 |
| --- | --- | --- | --- |
| Claude Code Game Studios（下稱「模板」） | `v1.3.0`（`abc0de7`） | `.claude/`、`docs/engine-reference/`、`project.yaml` | MIT，`.claude/LICENSE-claude-code-game-studios` |
| GUT（Godot 單元測試） | `9.7.1` | `addons/gut/`、`.gutconfig.json` | MIT，`addons/gut/LICENSE.md` |
| GUT skill（`/gut`） | `rockerBOO/gut-skill` `0259877`，**本組改過** | `.claude/skills/gut/` | GPL-3.0，同資料夾 `LICENSE` |

- 模板**整包照搬**，沒有刪檔 —— 它的檔案互相引用，裁剪會讓指令靜默失效（`VISION.md` §10）。只改了兩處：`settings.json` 拿掉 hooks 與狀態列（§4），以及**不搬**它的根目錄 `CLAUDE.md`（那份會讓每個 session 都套它的工作室流程）。
- GUT skill 原文寫於 Godot 4.7 之前，double 的回傳值已過時。改了什麼寫在 `SKILL.md` 開頭。
- 工具版本變動要在 `ai-log` §1 加一列（`VISION.md` §10）。

## 2. 環境

- **Godot 4.7.2**：命令列叫得到 `godot`。Windows 用 `_console.exe` 那個執行檔，才看得到輸出。
- **clone 後先 import 一次**，否則 `GutTest` 等 class 找不到：`godot --headless --path . --import`
- **Python 3**：模板部分腳本要用。只用 agent 與 `/gut` 的話不需要。

## 3. 跑測試

```bash
godot --headless -d -s addons/gut/gut_cmdln.gd --path . -gexit
```

- 測試放 `test/`，檔名 `test_*.gd`，`extends GutTest`。設定在 `.gutconfig.json`。
- 結束碼 `0` 全過、`1` 有失敗。
- 純邏輯 class 不繼承 `Node`（`SYSTEM.md` S1），直接 `new()` 來測，不用起場景。
- 寫測試時叫 `/gut`，或直接說「用 GUT 寫測試」，Claude 會自動載入。
- `project.yaml` 的 `commands.test` 已設成上面這行，模板的 agent 會跑 GUT，不會跑它預設的 gdUnit4。

## 4. hooks 為什麼關掉

模板有 18 個 hook，腳本都在 `.claude/hooks/`，但沒有在 `settings.json` 啟用。開著會：

- 每次開 session 注入「NEW PROJECT … Run: /start」，把 agent 帶往模板的設計文件流程，繞過 Gate A
- commit 時套用模板的規範（遊戲數值要放資料檔、TODO 要寫 `TODO(名字)`），本組沒定過這些
- 在 repo 寫 session log（`production/session-logs/`）
- 每次開 session 連 GitHub 檢查新版

想單獨打開某個 hook，改 `WORKFLOW.md` 的程序走（兩人同意），並在 `ai-log` §1 揭露。

**注意：`.claude/rules/` 沒有關，也關不掉** —— agent 讀寫符合路徑的檔案時，Claude Code 會自動載入對應規則。會碰到的：

| 規則 | 什麼時候生效 | 影響 |
| --- | --- | --- |
| `scene-files.md` | 任何 `.tscn`、`.tres` | 手改場景檔的注意事項（不改 `format=`、不自造 `uid://`、`.uid` 要一起 commit）。有用，留著 |
| `gameplay-code.md`、`ui-code.md`、`ai-code.md`、`engine-code.md` | 程式放在 `src/gameplay/`、`src/ui/`、`src/ai/`、`src/core/` | 模板的寫碼規範，例如「遊戲數值一律放資料檔」。本組沒定過 |
| `test-standards.md` | 測試放在 `tests/` | 以 gdUnit4 為準。**所以本組測試放 `test/`（單數）** |

程式目錄還沒定。定的時候若用到 `src/` 底下那幾個名稱，就等於採用了那幾份規範 —— 要嘛接受並寫進 spec，要嘛換個目錄名。

## 5. 怎麼搭配本組流程

**可以用的 agent**（在對話裡說「用 `<名稱>` agent」）：

| 本組職能 | 模板 agent |
| --- | --- |
| Implementer | `godot-gdscript-specialist`、`gameplay-programmer`、`ai-programmer`（殖民者行為）、`ui-programmer` |
| Analyst 的參謀 | `systems-designer`、`economy-designer`（資源） |
| Verifier | `qa-tester` —— 仍要開新 session、只給 feature 檔與 diff（`WORKFLOW.md` §6） |

agent 提的需求若 `VISION.md` 與訪談追不到，照樣標 `INV`。

**可以用的 skill**：`/gut`、`/balance-check`、`/perf-profile`、`/bug-report`、`/prototype`（只在 `spike/` branch 用）。

**不要用的 skill** —— 它們會產生本組流程沒有的文件，或改掉上面的設定：

| skill | 為什麼 |
| --- | --- |
| `/start`、`/setup-engine`、`/adopt`、`/onboard` | 改寫 `project.yaml`；`/setup-engine` 會把測試框架換成 gdUnit4 |
| `/test-setup`、`/test-helpers`、`/smoke-check` | 以 gdUnit4 為準 |
| `/create-epics`、`/create-stories`、`/story-*`、`/dev-story`、`/sprint-*`、`/estimate` | 本組的拆解是 feature 檔的 tasks |
| `/gate-check`、`/milestone-review`、`/scope-check` | 本組的關卡是 Gate A／B |
| `/design-system`、`/quick-design`、`/map-systems`、`/review-all-gdds`、`/create-architecture`、`/architecture-decision` | 本組的設計寫在 feature 檔與 `SYSTEM.md` |
| 發行類（`/release-checklist`、`/hotfix`、`/patch-notes` 等） | 交付物只是 prototype |

上面兩張清單是依 skill 名稱與說明分的，沒有逐一讀過內文。用了發現不合，回來改這份。

## 6. 升級

模板：從新 tag 重新照搬 `.claude/` 與 `docs/engine-reference/`，再重做 §1 的兩處修改。GUT：換掉 `addons/gut/`，看 release notes 有沒有破壞性變更，必要時同步改 `/gut` skill。兩者都要在 `ai-log` §1 加一列。
