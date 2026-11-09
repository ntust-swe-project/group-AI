<!-- 標題照 COMMIT_CONVENTION.md：<type>(<scope>): <subject>。內文上限 25 行，不要重述 feature 檔的內容 -->

## 做了什麼

<一到三行，連到 `docs/specs/features/NNN-<slug>.md`>

## 驗收結果

| 驗收條件 | 過 | 怎麼驗的 |
| --- | --- | --- |
| A1 | ✅ | GUT `test_xxx`（`5 passed`） |

<!-- 測試輸出只貼摘要行，失敗才貼那一段 -->

## Reviewer 看這四條

- [ ] diff 只動 tasks 範圍內的東西
- [ ] 驗收條件逐條過
- [ ] commit 數 = 核准次數
- [ ] ai-log 已更新

<!-- Gate B 要按 Approve，不是只留言。merge 用 merge commit，不要 squash -->

## 待辦／例外

<!-- 審查 agent 的結論一行（必填，§6） -->

無
