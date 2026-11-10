---
feature: 001-base-skeleton
owner: 組員 A
status: approved       # draft | approved | done
vision-refs: ["3.1", "3.2", "4.1", "6"]
---

# 001 — 雛型骨架

## Spec

### 這個 feature 要解決什麼

還沒有可以跑的遊戲，後面的 feature（需求、指派、建造、危機）沒有地方接。本 feature 只搭骨架：按下執行看得到太空站、幾個會走動的殖民者、往前走的天數。**不做任何遊戲機制。** 玩家感受到的：這是一座有人住的太空站，時間在走。

### 需求

| # | 需求 | 來源 |
| --- | --- | --- |
| R1 | 時間以天推進，畫面顯示目前第幾天與目標 30 天 | `VISION.md` §4.1；`SYSTEM.md` 時間推進、`Day` |
| R2 | 第 30 天走完後停止推進（要撐過第 30 天，不是一到第 30 天就結束） | `VISION.md` §4.1 |
| R3 | 單一固定佈局的太空站地圖，wireframe 呈現。目前只有一個**橢圓大廳**；地圖由房間組成，之後能再加房間 | `VISION.md` §6；`SYSTEM.md` §1「不做」 |
| R4 | 開場有 3 個殖民者，名字取自固定名字表 | 訪談 Q1；`VISION.md` §3.1；`SYSTEM.md` `Colonist` |
| R5 | 殖民者在站內自己走動、不穿牆，以格子移動 | `VISION.md` §3.2 的前提（殖民者自己執行，須能移動）；閒晃行為本身見 I1 |
| R6 | 殖民者集合可在執行中增加 | `SYSTEM.md` SC1 |
| R7 | 邏輯與畫面分離：天數、殖民者、找路是純邏輯 class，不繼承 `Node` | `SYSTEM.md` S1 |
| R8 | 可暫停；倍速 0.5×–4×，每檔 0.5 | I2、Q3 |
| R9 | 點殖民者看到他的名字 | `VISION.md` §3.1（個體）；面板本身見 I3 |
| R10 | 除錯操作：跳到下一天、加一個殖民者 | I4 |

### 驗收條件

| # | 驗收條件 | 對應需求 | 驗法 |
| --- | --- | --- | --- |
| A1 | 新局從第 1 天開始；累積滿一天的時間後變第 2 天 | R1 | GUT `test_day_clock` |
| A2 | 剛進入第 30 天時尚未結束；第 30 天走完後回報已結束，天數停在 30，之後再推進都不變 | R2 | GUT `test_day_clock` |
| A3 | 暫停時推進不改變天數；倍速 ×k 時，同樣的真實時間推進 k 倍；倍速只能是 0.5–4 之間 0.5 的倍數，調過頭停在邊界 | R8 | GUT `test_day_clock` |
| A4 | 新局殖民者 3 個、名字不重複且都在名字表裡；加一個後數量 +1 | R4、R6 | GUT `test_colony` |
| A5 | 找路結果不穿過牆格，起終點相同時路徑長度為 1 | R5 | GUT `test_station_grid` |
| A6 | `DayClock`、`Colony`、`Colonist`、`StationGrid` 的實例都不是 `Node` | R7 | GUT `test_logic_is_pure` |
| A7 | 執行遊戲：看得到橢圓大廳（未縮放時約佔畫面 6–7 成），牆緊貼地板外圍、站外不畫；格線粗細一致；3 個殖民者在大廳內走動且不穿牆 | R3、R4、R5 | 手動 |
| A8 | 執行遊戲：天數標籤隨時間更新；按暫停後停止、按快轉後變快；到第 30 天停住 | R1、R2、R8 | 手動（用快轉） |
| A9 | 點任一殖民者，面板顯示他的名字；點空地面板關閉 | R9 | 手動 |
| A10 | 按「下一天」天數 +1；按「加殖民者」地圖上多一個會走動的殖民者 | R6、R10 | 手動 |
| A11 | 橢圓房間內的格子是地板、緊貼地板外圍的一圈是牆、其餘是站外；再加一個房間並用走道接上後，兩房之間找得到路 | R3 | GUT `test_station_grid` |

### 不做什麼

- 生理、心理數值與其顯示（只留面板位置）；工作、指派、優先度、搶占
- 建造、設施、自動化；危機、失敗判定、結算畫面 —— 第 30 天只是停住
- 鏡頭移動與縮放（地圖放得進 1920×1080）；多房間佈局（只做到能加）、名字組合（名＋姓）—— 等實體出來再調整；選單、存檔、音效、任何美術（顏色只用來區分牆、地板、殖民者）；改 `project.godot` 的共用欄位

### 開放問題

| # | 問題 | 誰能答 | 狀態 |
| --- | --- | --- | --- |
| Q1 | 一天是幾秒真實時間？（VISION 說量級約 1 分鐘，非硬性） | 組內 | 已答：1× 時 5 分鐘，做成可調常數。一場 1× 150 分鐘、4× 37.5 分鐘，比 VISION 量級慢；組員 A 決定先保留彈性，靠變速調整 |
| Q2 | 初始殖民者 3 個還是 4 個？（客戶答 3–4） | 組內 | 已答：3 個（寫進 R4） |
| Q3 | 變速有幾檔、各幾倍？ | 組內 | 已答：0.5×–4×，每檔 0.5，共 8 檔，另有暫停（寫進 R8） |
| Q4 | 地圖佈局：幾個房間、怎麼連？格子多大、幾格寬高？ | 組內 | 已答：一個大廳，未縮放時約佔畫面 6–7 成（寫進 R3、A7）。格子大小實作時暫定為常數，實體出來後再調 |
| Q5 | 移動用格子（`AStarGrid2D`）還是自由移動（`NavigationAgent2D`）？見 Plan | 組內 | 已答：格子（寫進 R5） |
| Q6 | 殖民者名字從哪來？（固定名單／隨機產生） | 組內 | 已答：固定名字表，取自美國社安局近百年常見名（`ssa.gov/oact/babynames/decades/century.html`）。組合式之後再試 |

### AI 提出、待人類決定

| # | AI 提出什麼 | 標記 | 決定 | 理由 |
| --- | --- | --- | --- | --- |
| I1 | 沒事做時在房間之間閒晃 | INV | 納入 | 組員 A 同意：沒有工作系統前，殖民者要動才看得出找路是否正常 |
| I2 | 暫停與變速 | INV | 納入 | 組員 A 同意：一天 5 分鐘（Q1），沒有變速無法在合理時間內驗到第 30 天 |
| I3 | 點殖民者開資訊面板 | INV | 納入 | 組員 A 同意：之後的生理、心理數值與指派都從這個面板長出來 |
| I4 | 除錯操作（下一天、加殖民者） | INV | 納入 | 組員 A 同意：驗 SC1 與第 30 天不必真的等 |
| I5 | 程式目錄：`logic/`（純邏輯）、`scenes/`（場景與畫面腳本）、`test/`。避開 `src/gameplay/` 等，以免自動套用模板的寫碼規則（`TOOLS.md` §4） | INV | 納入 | 組員 A 同意 |
| I6 | 名字表用完時，取一個名字加數字（如 `James 2`），保證不重複 | INV | 納入 | 組員 A 同意：維持 SC1（數量不設上限）；開局 3 人、表有 200 名，base 階段只有除錯按鈕加到 200 人以上才會用到 |

## Plan

### 方案

- **純邏輯**（`extends RefCounted`）：`DayClock` 吃真實秒數 `advance(delta)`，處理天數、暫停、倍速、第 30 天停止。`Colony` 持有殖民者陣列（不假設數量，SC1）。`Colonist` 目前只有 id 與名字，名字從 `colonist_names.gd` 不重複抽取。一天長度、倍速範圍、地圖尺寸、格子大小、走路速度都是具名常數，方便之後調整；後三者是實作時的暫定值（大廳 48×27 格、每格 32 px、每秒 2 格），驗收時再定。`StationGrid` 包一個 `AStarGrid2D`，格子分站外、牆、地板三種：地圖由房間（矩形、橢圓）與走道疊成，房間內是地板，緊貼地板的外圍自動成牆，站外與牆都設成 solid。
- **畫面**：`main.tscn` 持有上述邏輯物件，每幀呼叫 `advance`。地圖用 `_draw()` 畫格子，殖民者是圓點加名字，沿 `StationGrid` 的路徑移動。HUD 放天數、變速按鈕、資訊面板、除錯按鈕。
- **建議 Q5 用格子**：`AStarGrid2D` 是 `RefCounted`，找路能留在邏輯層用 GUT 測（A5），之後建造放設施也自然對齊格子。自由移動要靠場景樹裡的 `NavigationRegion2D`，邏輯層測不到。

### 要動的檔案

| 檔案 | 新增／修改 | 做什麼 |
| --- | --- | --- |
| `logic/day_clock.gd`、`colony.gd`、`colonist.gd`、`station_grid.gd`、`colonist_names.gd`、`wanderer.gd` | 新增 | 純邏輯；名字表是常數陣列；`Wanderer` 管閒晃 |
| `scenes/main.tscn`／`.gd` | 新增 | 組合邏輯與畫面 |
| `scenes/station_map.gd`、`colonist_view.tscn`／`.gd`、`hud.tscn`／`.gd` | 新增 | 地圖、殖民者、HUD |
| `test/test_day_clock.gd`、`test_colony.gd`、`test_station_grid.gd`、`test_logic_is_pure.gd`、`test_wanderer.gd`、`test_main_scene.gd`、`test_hud.gd`、`test_info_panel.gd`、`test_debug_bar.gd` | 新增 | A1–A6；A7–A10 的接線（外觀仍手動驗） |
| `project.godot` | 修改 | 只加 `run/main_scene`，非共用欄位 |

動到 `project.godot` 共用欄位嗎：否（`run/main_scene` 不屬共用的版本、renderer、解析度、stretch）

### 引擎 API 驗證

對本機 Godot 4.7.2 `--dump-extension-api` 逐一核對（2026-11-10）；`AStarGrid2D` 不在 `docs/engine-reference/` 涵蓋範圍，以引擎實際 API 為準。

| API | 狀態 | 文件連結 |
| --- | --- | --- |
| `AStarGrid2D`：`region`、`cell_size`、`diagonal_mode`、`update()`、`set_point_solid()`、`get_id_path()`、`is_in_boundsv()`、`is_point_solid()`；繼承 `RefCounted` | 已驗證 | `docs.godotengine.org/en/4.7/classes/class_astargrid2d.html` |
| `CanvasItem`：`_draw()`、`draw_rect()`、`draw_circle()`、`queue_redraw()`、`get_global_mouse_position()` | 已驗證 | `.../class_canvasitem.html` |
| `Node._process()`、`Node._unhandled_input()`、`InputEventMouseButton` 的 `button_index`／`pressed`／`position`、`Node2D.to_local()`／`to_global()`、`Viewport.set_input_as_handled()` | 已驗證 | `.../class_node.html` |
| `BaseButton.pressed`、`Label.text`、`Node2D.position`、`RandomNumberGenerator.randi_range()` | 已驗證 | `.../class_basebutton.html` 等 |

### Tasks

- [x] **T1** — `DayClock` 與測試 ／ 驗收：A1、A2、A3
- [x] **T2** — `Colony`、`Colonist` 與測試 ／ 驗收：A4
- [x] **T3** — `StationGrid` 與測試，加上邏輯純度測試 ／ 驗收：A5、A6
- [x] **T4** — `main.tscn` 與地圖繪製，設 `run/main_scene` ／ 驗收：A7（地圖部分）
- [x] **T5** — 殖民者顯示與閒晃移動 ／ 驗收：A7
- [x] **T6** — HUD：天數與變速 ／ 驗收：A8
- [x] **T7** — 資訊面板 ／ 驗收：A9
- [x] **T8** — 除錯按鈕 ／ 驗收：A10
- [ ] **T9** — 橢圓大廳與房間結構，格線每條只畫一次且不受縮放影響 ／ 驗收：A7、A11

## Gate A — 實作前核准

Owner：組員 A　日期：2026-11-10　結果：核准（第 5 次，重簽 changelog 第 5 列的橢圓大廳與 T9）

- [x] Owner 讀過 feature 檔全文（不是摘要）
- [x] 每條需求追得到來源；追不到的已標 `INV` 並決定去留
- [x] 驗收條件照著操作就能判斷過或不過
- [x] 「不做什麼」有寫
- [x] 每個 task 對到一條驗收條件，沒有孤兒，且一輪做得完
- [x] Godot API 全部對 4.7 文件驗過，無 `unverified`
- [x] 開放問題清零，或標「延後到 NNN」

看了什麼、注意到什麼（一到三句，不要只打勾）：讀過全文。注意到的都已在 S1 提出並改進本檔：一天 5 分鐘比 VISION 量級慢，靠 0.5×–4× 變速保留彈性（Q1）；地圖先一個大廳、格子大小暫定，等實體出來再調（Q4）。I1–I5 都是骨架必要的開發與驗證手段，全部納入。

## Gate B — merge 前

檢查表在 PR 模板，這裡只記結果。PR：#__　Owner 自審日期：____　退回次數：__

## 驗收結果

| 驗收條件 | 過 | 怎麼驗的 |
| --- | --- | --- |
| A1 | ✅ ／ ❌ | |

## Changelog

| 日期 | 改了什麼 | 為什麼 |
| --- | --- | --- |
| 2026-11-10 | 初版 | 立項 |
| 2026-11-10 | R2、A2：第 30 天要走完才結束。原本一進入第 30 天就結束，第 30 天長度為 0 | T1 審查 agent 指出；`VISION.md` §4.1 是「撐過 30 個遊戲天」，組員 A 選擇走完第 30 天。`status` 回 `draft`，重跑 Gate A |
| 2026-11-10 | 新增 I6：名字表用完時加數字 | T2 審查 agent 指出這是 AI 自行決定、spec 沒寫的行為；組員 A 選擇納入 |
| 2026-11-10 | Plan 補上實作中多出的檔案（`wanderer.gd`、5 個測試檔）與 API（`is_point_solid()`、滑鼠點擊相關），並寫明三個暫定值 | 審查 agent 指出 Plan 檔案表與 API 表未涵蓋；暫定值原本只寫在程式註解裡 |
| 2026-11-10 | R3、A7 改為橢圓大廳、地圖由房間組成、格線粗細一致；新增 A11、T9 | 組員 A 驗收前看截圖提出：大廳要橢圓、之後要能加房間；格線在縮放後粗細不均 |
