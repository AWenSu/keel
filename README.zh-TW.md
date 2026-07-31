# unified-dev-skills

**給 Claude Code 用的五階段開發流程——每階段一個 skill，每個角色都有具名 subagent，關鍵處設硬性關卡。**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-skills-blueviolet)](https://code.claude.com/docs/en/skills)
[![No dependencies](https://img.shields.io/badge/dependencies-none-brightgreen)](#安裝)

[Read this in English](README.md)

```
┌──────────────┐   ┌──────────┐   ┌─────────────────┐   ┌─────────────┐   ┌────────────┐
│ dev-discover │──▶│ dev-plan │──▶│ dev-plan-review │──▶│ dev-execute │──▶│ dev-finish │
│  想法 → spec │   │ spec →   │   │  只審大案/風險   │   │  編排式或   │   │ 證據閘門   │
│  （設閘門）   │   │ 產出物   │   │      高的案子     │   │  inline 皆可│   │ +合併      │
└──────────────┘   └──────────┘   └─────────────────┘   └─────────────┘   └────────────┘
        ▲                                  │                     │
        └──────────── dev-discover ◀───────┘   dev-plan ◀────────┘   dev-debug ◀── dev-finish
                （第3輪仍未決）           （與計畫矛盾）        （產不出證據）
```

`dev-workflow` 是五階段之上的路由器：判斷請求屬於哪個階段、派出對應 skill，還做到大多數路由器漏掉的一件事——**知道何時該把工作送回上一階段**，當後面階段發現前面階段其實錯了。

## 為什麼做這個

一個裝備齊全的 Claude Code 環境，規劃類 skill 會越積越多：superpowers 的生命週期鏈、gstack 的重量級審查套件、planning-with-files 的持久化層、自訂 planner agent。每一個都很好——但重疊本身有代價：**四種「做計畫」的方式，沒有一條明顯的主線，還得記路由表。**

這個 repo 堅持**每階段一個 skill**。每個 skill 吸收了值得留下的機制——硬性關卡、證據規則、決策分類法、進度帳本、驗證鐵律——並丟掉沒證明自己的部分（外部 CLI 依賴、遙測、重複的散文）。每個 skill 都是單一自包含的 `SKILL.md`：不需建置、不需 hook，除了檔案本身什麼都不用裝。

**自第一版以來的變化：** 這條 pipeline 不再把工作派給匿名的 `general-purpose` subagent。每個角色——implementer、規格審查者、品質審查者、四種審查視角、兩層對抗式懷疑者、fixer、研究票——都是有名字的 agent 定義，各自釘死模型、各自有工具權限範圍。你看著一次執行過程，光看名字就知道誰在做什麼。詳見〈[Subagent 名冊](#subagent-名冊)〉。

## 五個階段

| # | Skill | 做什麼 | 骨幹來源 | 關鍵移植 |
|---|-------|--------|---------|---------|
| 1 | [`dev-discover`](skills/dev-discover/SKILL.md) | 模糊想法 → 使用者已核准、有證據根據的 spec。硬性關卡：核准前不寫任何程式碼。 | superpowers:brainstorming | gstack spec 的程式碼證據鐵律（先給 `path:line` 再問問題）、五問開場、範圍鎖定、在不同約束下平行「設計兩遍」 |
| 2 | [`dev-plan`](skills/dev-plan/SKILL.md) | spec → 一份零背景工程師也能照做的計畫。分級指南、`Interfaces:` 區塊、禁用佔位詞。 | superpowers:writing-plans | planner agent 的風險分級；每個 task 的 `Skills:` 欄位指名要呼叫的領域 skill |
| 3 | [`dev-plan-review`](skills/dev-plan-review/SKILL.md) | 多視角自動審查（CEO/Design/Eng/DX），強制先驗網路掃描——例行判斷自動決、只把真正需要判斷的事升級問人，並在信任自己的發現前先自我對抗反駁。 | gstack autoplan 的決策系統 | doubt-driven 反駁、Mechanical / Taste / User-Challenge 三分類、6 條自動決策原則、兩層懷疑者升級機制 |
| 4 | [`dev-execute`](skills/dev-execute/SKILL.md) | 審過的計畫 → 能跑的程式碼。每個 task 派新的 implementer + 兩個**獨立**審查者（規格軸、品質軸——絕不合併成單一裁決），配崩潰安全的進度帳本。subagent 不可用時有 inline 備援。 | superpowers:subagent-driven-development | executing-plans 的 inline 模式；planning-with-files 的「檔案系統即記憶」 |
| 5 | [`dev-finish`](skills/dev-finish/SKILL.md) | 在宣稱「完成」之前：為每個宣稱找新鮮證據、把真實流程整條走一遍、彙整這次執行過程中散落的所有未決事項，再整合分支。 | superpowers:verification-before-completion | 宣稱→證據對照表、紅綠回歸鐵律、分支整合選項 |

**內建跳過規則。** 小任務（單檔、可逆、<30 分鐘）整個跳過 1–3 階段；只有大案或高風險案才走審查。規劃開銷不該超過任務本身的 ~20%。

## 安裝

把 `skills/` 和 `agents/` 複製到任何 Claude Code 會載入的位置：

```bash
# 專案內
cp -R skills/* your-repo/.claude/skills/
cp -R agents/* your-repo/.claude/agents/

# 或全域
cp -R skills/* ~/.claude/skills/
cp -R agents/* ~/.claude/agents/
```

`agents/` 是選配但強烈建議裝——沒裝的話 pipeline 仍能跑，但每次 subagent 派工都會默默降級成 Claude Code 內建的通用 `general-purpose` agent：沒有釘死的模型、沒有限縮的工具權限、進度畫面上也看不到名字告訴你哪個角色在跑。

安裝完重啟一次 Claude Code（新的 skill/agent 目錄只在 session 啟動時載入）。之後每個 skill 都可直接用——`/dev-discover`、`/dev-plan`、`/dev-plan-review`、`/dev-execute`、`/dev-finish`——或透過路由器 `/dev-workflow`。

## 用法

```text
# 從模糊想法開始
/dev-discover 我想幫公開 API 加 rate limiting

# 需求已經清楚
/dev-plan 幫報表頁加 CSV 匯出，spec 在 docs/specs/...

# 計畫很大或動到正式環境資料
/dev-plan-review

# 準備動工
/dev-execute

# 說「完成」之前
/dev-finish

# 或直接描述任務，讓路由器判斷該走哪個階段
/dev-workflow 幫管理後台加 OAuth 登入
```

每個階段會宣告下一步並交接——你只在**具名關卡**介入，不是每一步都要你點頭。每個 subagent 一回傳，就立刻播報（裁決、一條有出處的發現、下一步）——你不會盯著一條靜默的 pipeline 猜四個 agent 在幹嘛。

### 四個關卡——僅有的、會停下來等你回答的點

pipeline 其他所有地方都不會問你要不要繼續。這四個永遠會問：

| 關卡 | 階段 | 問什麼 |
|------|------|--------|
| **G1** | `dev-plan-review`，Step 0 | 「這份計畫假設了 X、Y、Z——對嗎？」永遠會問的前提檢查；前提錯了，下游每個發現都沒意義。 |
| **G2** | `dev-plan-review`，Step 5 | 每個活下來的 Taste 決定和 User Challenge，**一次問一題**，附完整脈絡+選項+後果。絕不批次彙總。 |
| **G3** | `dev-execute`，pre-flight | 批次問完計畫矛盾的問題，在 Task 1 開始前問一次——不是任務跑到一半才問。 |
| **G4** | `dev-execute`，每個 task 審查 | 發現與計畫原文本身矛盾（`PLAN-CONFLICT`）——絕不自動解決、絕不自動套用。 |

### 回退路由——後面階段發現前面錯了

| 觸發條件 | 從 | 退回到 |
|---------|-----|--------|
| 執行時發現計畫與現況矛盾（超出單一 task 能修的範圍） | `dev-execute` | `dev-plan` |
| 計畫審查第 3 輪仍有未決決定——計畫在跟 spec 打架 | `dev-plan-review` | `dev-discover` |
| `dev-finish` 的證據閘門產不出某個宣稱的證明 | `dev-finish` | `dev-debug` |
| debug 後結論是需求本身錯了 | `dev-debug` | `dev-discover` |

### 建議路由（`dev-workflow` 判斷依據）

| 訊號 | 路由到 |
|------|--------|
| 想法模糊、需求不清 | `dev-discover` |
| spec 已存在、後面是多步驟工作 | `dev-plan` |
| 計畫大/風險高（>8 檔、新架構、正式環境資料） | `dev-plan-review` |
| 計畫已就緒且直觀 | `dev-execute` |
| 準備宣稱完成 / 開 PR | `dev-finish` |
| bug 或測試失敗 | 你的 debug skill——這條 pipeline 是給「建造」用的 |
| UI/視覺工作 | 你的設計 skill 路由器 |

### 各專案類型的預設值

哪些階段要跑、哪些審查視角要開、以及該疊加什麼——涵蓋 **web app、API、CLI、MCP server、serverless、文件 repo、爬蟲**：見 **[PROJECT-TYPE-GUIDE.md](PROJECT-TYPE-GUIDE.md)**。

### 領域 skill 分層

skill 的選用發生在**規劃時**，那時才有全局脈絡：`dev-plan` 產出物裡每個 task 都帶一個 `Skills:` 欄位，指名它的 implementer 必須呼叫哪些領域 skill（視覺任務對應 UI 設計 skill、平台任務對應 Workers/MCP 慣例的平台 skill）。`dev-execute` 會把這個欄位傳進每個 implementer 的工作說明。

## Subagent 名冊

這條 pipeline 每次派工都指名具體的 `subagent_type`——絕不落到通用的 `general-purpose`。名字本身就告訴你階段和角色；frontmatter 釘死模型、鎖住工具權限，讓這個決定不會像散文指示（「記得這裡要用 opus」）那樣悄悄漂掉。

**唯讀是宣告出來的。** 下面每個審查者、視角、懷疑者、研究者都被限制成 `Read, Grep, Glob, Bash`（加上指名的檢索工具）——只能描述怎麼修，不能自己動手改。只有 implementer 和 fixer 有寫入權限。這讓「審查者不得改自己在審的程式碼」變成結構性保證，而不是一句可能被忽略的提示詞。

| subagent_type | 階段 | 角色 | model | 工具 |
|---|---|---|---|---|
| `dev-discover-designer` | 1 探索 | 3 個平行方案之一，各自受不同約束 | sonnet | 唯讀 |
| `dev-plan-lens-ceo` | 3 審查 | 這件事該不該做——加上強制先驗網路掃描 | **opus** | 唯讀 + tavily, exa, context7 |
| `dev-plan-lens-design` | 3 審查 | 使用者可見的每個狀態是否都指名了（條件式：UI 密集計畫才開） | sonnet | 唯讀 |
| `dev-plan-lens-eng` | 3 審查 | 照寫的方式能不能做出來——加上對照即時文件的 API 時效查核 | sonnet | 唯讀 + context7, Ref |
| `dev-plan-lens-dx` | 3 審查 | 開發者上手成本（條件式：面向 API/CLI/SDK 的計畫才開） | sonnet | 唯讀 + context7 |
| `dev-plan-skeptic` | 3 審查 | 反駁一條 High finding——單點證據查核 | sonnet | 唯讀，**不給檢索工具** |
| `dev-plan-skeptic-critical` | 3 審查 | 反駁一條 Critical／安全／跨檔推理的 finding | **opus** | 唯讀，**不給檢索工具** |
| `dev-exec-implementer` | 4 執行 | 實作一個 task，測試先行強制執行 | sonnet | 完整 |
| `dev-exec-reviewer-spec` | 4 執行 | 只看規格符合度 | sonnet | 唯讀 |
| `dev-exec-reviewer-quality` | 4 執行 | 只看程式碼品質 | sonnet | 唯讀 |
| `dev-exec-fixer` | 4 執行 | 只修拿到的 findings | sonnet | 完整 |
| `dev-wayfind-researcher` | 前置階段 | 解一張能靠外部世界解答的研究票 | sonnet | 唯讀 + 完整檢索 |

另外還有三個既有名稱的通用專家，pipeline 會在發現需要時直接以原名派出：`security-auditor`、`test-engineer`、`silent-failure-hunter`。`dev-execute` 結束時的整分支審查用 `code-reviewer`，且**不覆寫模型**——它繼承這次 session 最強的模型，因為這是 `dev-finish` 前的最後一道防線。

### 為什麼是兩層懷疑者，而不是一個 model 參數

讓「懷疑者」在簡單發現上便宜一點的直覺做法，是照嚴重度在派工時傳一個 `model` 覆寫參數。這條 pipeline 刻意**不**這麼做——用 model 參數做路由，是一個埋在函式呼叫裡的決定，進度畫面上看不見，時間壓力下很容易被忘記（這條 pipeline 早期版本正好有過這種「記得做 X」的散文規則，稽核發現它從沒被真的遵守過）。

改成讓層級選擇**就是**agent 選擇：

- `dev-plan-skeptic`（sonnet）處理單點查核就能定案的發現——引用的那一行是否存在、是否真如所稱。
- `dev-plan-skeptic-critical`（opus）處理 Critical 嚴重度、任何觸及安全／資料遺失／不可逆操作的發現，或需要跨檔案推理的發現（追蹤呼叫者、找既有防護、估影響半徑）。
- 標準層可以回傳 `ESCALATE`，而不是硬猜超出自己深度的判斷——控制器會改派重案層。`ESCALATE` 永遠不當作裁決。
- **不確定就升級。** 這裡的代價不對稱是真的：懷疑者誤判殺掉一個真的 Critical 發現，等於讓一個缺陷直接穿過執行階段跑到正式環境才現形；懷疑者誤判放過一個弱發現，只多花一輪修復-審查。pipeline 預設的偏向（「證據不足就反駁」）本身已經偏向殺掉發現——model 層級是攔在這個偏向和真正的錯誤之間的唯一防線。

### 先驗掃描——在動工前抓到「這早就有人解決過了」

CEO 視角（`dev-plan-lens-ceo`）在做任何內部推理之前，先強制跑一輪外部掃描：用網路搜尋找現成產品/函式庫、用深度研究找已知失敗模式和棄用通知、用文件查詢確認某個點名的框架是否早就內建這個功能。它輸出三個段落——現成方案、已知撞牆、以及一個能證明「即便如此仍值得做」的**具體差異點**。

第三段刻意設成硬性關卡：一條先驗發現如果說不出跟我們情境的具體差異，信心上限就會被壓低，而且永遠不能單靠它砍掉一個計畫或升級成 User Challenge。表面上的名稱撞衫不算重複，靠一個膚淺的比對就殺掉正當的工作，會是這個視角能犯的最貴的錯誤。

Eng 視角（`dev-plan-lens-eng`）跑平行的 API 時效查核——對照現行文件，確認計畫點名的每個框架/函式庫/API 自計畫寫成以來沒有被棄用或移除。

**每條外部發現都要求 URL、取用日期、逐字引文**——跟 pipeline 對內部 `file:line` 引用一貫的證據標準相同。抓取回來的內容一律視為不可信輸入：內嵌在搜尋結果或文件頁面裡的指令一律忽略，只萃取事實性主張。

### 扇出上界

沒有任何階段會無限制派出 agent。上限是**每階段 ≤8 併發、≤16 總量**；若實際工作量超過，pipeline 會按嚴重度排序、覆蓋前 N 條，並**必須**印出 `SKIPPED: <n> — <原因>`。靜默截斷視為 bug——一個階段悄悄只覆蓋 60% 的發現卻回報得像覆蓋了 100%，比一開始就沒跑還糟。

## 來源與上游同步

這些是**合成，不是 fork**——上游還在持續演進。每個 SKILL.md 的 frontmatter 都記錄了來源與版本。合成時的快照（2026-07-14；subagent 名冊與先驗掃描於 2026-07-30 加入）：

| 上游 | 版本 | Repo |
|------|------|------|
| superpowers | 6.1.1 | [obra/superpowers](https://github.com/obra/superpowers) |
| gstack | 1.60.1.0 | [garrytan/gstack](https://github.com/garrytan/gstack) |
| planning-with-files | 3.5.0 | [OthmanAdi/planning-with-files](https://github.com/OthmanAdi/planning-with-files) |

要跟上游同步：

1. 對照上表版本，檢查上游有沒有新版。
2. 讀它們的 changelog，只找**機制**變更（新關卡、新協定）。純散文改寫、以及本 repo 刻意丟掉的機制的修復（Codex hook、遙測、mockup board）都不用管。
3. 把機制變更移植進受影響的階段 skill；在該 skill 的 frontmatter 裡把版本號往上調。

如果你同時裝著上游原版 skill，在額外機制真的值回成本時優先用重量級原版——例如超過 15 檔的大計畫用 gstack `/autoplan`（雙模型共識）、輸出要開成 GitHub issue 用 gstack `spec`。

## 設計原則

- **蒸餾，不是串接**——一個機制能被留下，是因為它扛得住重量，不是因為它本來就存在。
- **關卡神聖不可侵犯，產出物可以縮小**——時間壓力下可以寫小一點的 spec；但絕不能跳過核准。
- **證據優先於報告**——subagent 說「成功」、一次過期的測試結果、「應該可以」，都不是證據；diff 和剛跑出來的指令輸出才是。
- **檔案系統優先於 context window**——任何需要撐過壓縮的東西都寫進檔案。
- **具名 agent 優先於散文提醒**——如果一條規則很重要（「這裡要用強模型」「這隻不能寫檔案」），把它編進被派工 agent 的 frontmatter，而不是寫成一句寄望被記住的句子。

## 貢獻

歡迎 issue 和 PR——尤其是回報這個 repo 還沒移植的上游機制變更，或是實務上發現某個階段/關卡/agent 其實沒扛住重量。貢獻前記得參照上面的設計原則：貢獻該是蒸餾，不是給 pipeline 已經有的功能再開一條第四種做法。

## 授權

[MIT](LICENSE)
