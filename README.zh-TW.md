# keel

**給 Claude Code 用的五階段開發流程。每個階段配一個 skill，每個角色都叫得出名字，關鍵地方卡關卡，不讓你亂衝。**

> *龍骨（keel）是造船時第一根立起來的結構樑，之後每一根肋骨都長在它上面。它歪了，整艘船就歪——這正是這條 pipeline 把最硬的關卡放在最前面的理由。*

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-skills-blueviolet)](https://code.claude.com/docs/en/skills)
[![No dependencies](https://img.shields.io/badge/dependencies-none-brightgreen)](#安裝)

[English version](README.md)

```
┌──────────────┐   ┌──────────┐   ┌─────────────────┐   ┌─────────────┐   ┌────────────┐
│ keel-discover │──▶│ keel-plan │──▶│ keel-plan-review │──▶│ keel-execute │──▶│ keel-finish │
│  想法→spec   │   │ spec→計畫│   │  只審大案/高風險 │   │  可編排可   │   │  查證據、  │
│（卡核准關）   │   │          │   │                 │   │  inline 兩用│   │  才准合併  │
└──────────────┘   └──────────┘   └─────────────────┘   └─────────────┘   └────────────┘
        ▲                                  │                     │
        └──────────── keel-discover ◀───────┘   keel-plan ◀────────┘   keel-debug ◀── keel-finish
                （吵三輪還吵不完）        （跟計畫對不上）        （拿不出證據）
        ▲
        └──────────────────────────────────── 上線後 Signals 回報為負
                                              （是需求錯了，不是程式錯）
```

`keel-workflow` 是五個階段之上的總機：判斷這次的請求該進哪個階段、派對應的 skill 去做，還幹了一件大部分路由器懶得做的事——**知道什麼時候該把工作退回去**，因為後面的階段常常會發現，前面那階段其實搞錯了。

## 為什麼要搞這套

Claude Code 裝備齊全一點，規劃類的 skill 就會越堆越多：superpowers 一整條生命週期鏈、gstack 重量級審查套件、planning-with-files 的持久化機制、還有各種自訂 planner。每一個單獨拿出來都不錯，但擺在一起就麻煩了：**「做計畫」有四種做法，沒有一條主線，還得背路由規則才知道現在要用哪個。**

這個 repo 只留**每階段一個 skill**。有用的機制才留下——硬性關卡、證據規則、決策分類、進度帳本、驗證鐵律；沒用的就砍（外部 CLI 依賴、遙測、重複的廢話）。每個 skill 就一份自包含的 `SKILL.md`，不用建置、不用掛 hook，除了檔案本身什麼都不用裝。

**跟第一版比，這次改了什麼：** pipeline 不再把工作丟給一個沒名字的 `general-purpose` subagent 打混。implementer、規格審查、品質審查、五種審查視角、兩層懷疑者、fixer、研究票——每個角色都是獨立命名的 agent，模型釘死、工具權限也鎖死。你盯著畫面看誰在跑，光看名字就知道現在誰在幹嘛，不用猜。細節看下面〈[Subagent 名冊](#subagent-名冊)〉。

## 五個階段在幹嘛

| # | Skill | 做什麼 | 骨幹抄哪來 | 從哪嫁接了什麼 |
|---|-------|--------|-----------|---------------|
| 1 | [`keel-discover`](skills/keel-discover/SKILL.md) | 模糊想法 → 使用者點頭認可、有憑有據的 spec。規矩很硬：沒核准就不准動一行程式碼。 | superpowers:brainstorming | gstack spec 那套「先甩證據再問問題」、開場五問、範圍先鎖死、同一個問題在不同限制下平行想兩套做法；**先驗掃描不只查 repo 內、也上網查**——adopt／adapt／build 變成一個有記錄、有具體差異點的決定，就算決定自己造，也會把成熟方案的功能清單撈回來；spec 帶 `Status: draft\|approved` 核准閘門、`Spec Version` 欄位、Success Criteria 改寫成 Given-When-Then |
| 2 | [`keel-plan`](skills/keel-plan/SKILL.md) | spec → 一份就算完全不懂這個 codebase 的工程師也能照做的計畫。分大小的指南、`Interfaces:` 區塊、禁止空話佔位。 | superpowers:writing-plans | planner agent 的風險分級；每個 task 上的 `Skills:` 欄位，先講清楚該叫哪些領域 skill；mattpocock to-tickets 的垂直切片任務框架、拆完票先問粒度/依賴對不對的 quiz；UI 相關的計畫強制多產出一段 `### 2b.` feature matrix |
| 3 | [`keel-plan-review`](skills/keel-plan-review/SKILL.md) | 五個視角（CEO/Design/Eng/Security/DX）自動輪流審，還會主動上網查有沒有人早就做過或早就撞牆。例行的自己拍板，真的要人判斷的才丟回來問，而且丟出結論前自己先反駁自己一輪。 | gstack autoplan 的決策系統 | 自我懷疑反駁法、Mechanical / Taste / User-Challenge 三分法、6 條自動拍板原則、兩層懷疑者升級機制；Step 5 決策一過自動拍板門檻就當場產出一段式 ADR |
| 4 | [`keel-execute`](skills/keel-execute/SKILL.md) | 審完的計畫 → 能跑的程式碼。每個 task 都是新開一個 implementer，配二到三個**互相看不到彼此**的審查者（規格對不對、寫得好不好，R4 條件命中時再加一軸資安——二至三軸絕不混成一個裁決）。進度帳本掉線也不會丟資料。subagent 用不了時還有 inline 備援。 | superpowers:subagent-driven-development | executing-plans 的 inline 模式；planning-with-files 那套「檔案系統就是記憶體」；起手前先比對計畫記錄的 `Spec Version` 有沒有跟 spec 現況對不上；G6 plan-conflict 閘門在 INLINE 模式也重申一次；改到本 repo 自己的 skill 檔時，Finish 階段額外回報對照 `eval-fixtures/RULE-INVENTORY.md` 的 `FIXTURE COVERAGE` |
| 5 | [`keel-finish`](skills/keel-finish/SKILL.md) | 敢說「完成」之前：每個宣稱都要有剛查出來的新鮮證據、真的把整條流程走一遍、把這次過程中散落各處的未決事項全部收攏，最後才合併分支。 | superpowers:verification-before-completion | 宣稱對照證據表、紅燈變綠燈的回歸鐵律、分支整合怎麼選；已有 Step-5 ADR 的宣稱不用重查，Success Criteria 改成請使用者當場核對而非重新推導；Part 2c 的洩密掃描檢查項寫明裝好時該跑的確切指令 `gitleaks detect` |

**內建跳過規則。** 小事（改一個檔、可逆、30 分鐘內搞定）直接跳過 1–3 階段。只有大案或風險高的案子才走完整審查。規劃花的時間不該超過任務本身的兩成。

**回歸測試 pipeline 自己的規則。** [`eval-fixtures/`](eval-fixtures/) 用兩種方式驗證 keel 自己。`check-structure.sh` 是腳本——每隻 agent 都釘死 model 與工具清單、沒有唯讀 agent 拿到寫入權限、每個被派工的名字都找得到定義檔。動本 repo 前先跑：

```bash
bash eval-fixtures/check-structure.sh    # 22 條檢查，exit 0 = 全過
bash eval-fixtures/run-mutations.sh      # 證明上面每條檢查真的會紅
bash tables/render.sh                    # 重新生成三張重複的表
```

第二支才是重點。它把 55 個真實缺陷（五輪獨立稽核跑過的每一個突變）逐一注入拋棄式副本，斷言指定的那條檢查變紅。最後一條斷言是**每條檢查都必須至少有一個突變**——沒有人測過的檢查會讓整個 run 失敗。

**出現在一份以上文件裡的規則，只有一份正本。**[`rules/`](rules/) 存每條規則的正本文字，凡是要陳述該規則的檔案都逐字帶那句話，檢查比對的是位元組，不是 pattern。要改規則就三步：改 `rules/<rule>.txt`、跑檢查、把新句子貼進它點名的每個檔案。只改其中一份複本會直接 FAIL——這正是目的，舊的失敗模式就是規則在某份文件改了、另外兩份一個月後才發現。抓不到的部分寫在 `rules/README.md`。

**有三張表各自出現在三份文件裡**——agent 名冊、關卡表、回退路由。原本有六條檢查在盯這九份副本，而五輪稽核在那六條檢查裡找到六個缺陷。現在改成生成：來源是 [`tables/`](tables/) 加上每隻 agent 自己的 frontmatter，`bash tables/render.sh` 重寫結構欄位，只留一條檢查確認沒人手改生成結果。表格裡的敘述文字不生成——三份文件的敘述本來就沒有一句相同，那是刻意的。

`NN-*.md` 則是腳本判斷不了的情境測試（spec 標 `draft` 會不會擋下 `keel-plan`？計畫與現況牴觸會不會退回？），靠走查。`RULE-INVENTORY.md` 列出每一條已宣告規則、各自的執行點與驗證方式——沒有驗證方式的那列表示它可能無聲壞掉，`執行於` 空著的那列表示它現在就是壞的。

## 安裝

把 `skills/` 跟 `agents/` 丟到 Claude Code 會讀的地方：

```bash
# 只裝這個專案用
cp -R skills/* your-repo/.claude/skills/
cp -R agents/* your-repo/.claude/agents/

# 或全域裝一次到處用
cp -R skills/* ~/.claude/skills/
cp -R agents/* ~/.claude/agents/
```

`agents/` 這包選裝，但強烈建議裝——不裝，pipeline 一樣能跑，只是每次派工都會偷偷降級成內建的 `general-purpose`：模型沒釘死、工具權限沒鎖、進度畫面也看不出現在跑的是誰。

裝完重開一次 Claude Code（新的 skill/agent 目錄要重啟才會吃進去）。之後每個 skill 都能直接叫——`/keel-discover`、`/keel-plan`、`/keel-plan-review`、`/keel-execute`、`/keel-finish`，或是交給總機 `/keel-workflow` 自己判斷。

## 怎麼用

```text
# 從一個模糊的想法開始
/keel-discover 我想幫公開 API 加 rate limiting

# 需求已經很清楚了
/keel-plan 幫報表頁加 CSV 匯出，spec 在 docs/specs/...

# 計畫很大，或動到正式環境的資料
/keel-plan-review

# 東西都準備好了，開工
/keel-execute

# 講「做完了」之前先跑這個
/keel-finish

# 或懶得判斷，直接講任務，讓總機自己分流
/keel-workflow 幫管理後台加 OAuth 登入
```

每個階段做完會自己宣告下一站、直接交接——你只在**幾個具名關卡**才會被叫住，不是每走一步都要你點頭。子代理一回來，馬上播報結果（裁決、一條有出處的發現、接下來要幹嘛）——不會讓你盯著一片安靜的畫面猜四個 agent 到底在忙什麼。

### 關卡——唯一會停下來等你回答的地方

除了這些，pipeline 其他地方都不會停下來問你要不要繼續：

<!-- generated:gates — structure from tables/gates.tsv; run tables/render.sh after editing -->
| 關卡 | 在哪個階段 | 問什麼 |
|------|-----------|--------|
| **G1** | `keel-discover` | spec 核准。你沒點頭就不准寫程式碼，「這案子很簡單」也不例外。 |
| **G2** | `keel-plan` Step 6 | 拆票的粒度跟依賴邊對不對——只有計畫本來就要進 keel-plan-review 時才略過。 |
| **G3** | `keel-plan-review` Step 0 | 「這計畫假設 X、Y、Z 對不對？」——永遠會問的前提確認，前提錯了，後面查再多也白搭。 |
| **G4** | `keel-plan-review` Step 5 | 每個活下來的 Taste 決定、每個 User Challenge，一條發現一題，**依決策依賴關係分批**（見下），附完整脈絡、選項、後果。 |
| **G5** | `keel-execute` pre-flight | 計畫矛盾的問題先打包，Task 1 開工前一次問完——不是做到一半才冒出來煩你。 |
| **G6** | `keel-execute` 每個 task 審查 | 發現跟計畫原文對不上（`PLAN-CONFLICT`）——絕不自己決定怎麼修，也不自己套。 |
| **G7** | `keel-finish` Part 2 | 每一條 Success Criteria 請你當場核對。agent 自己的判斷永遠不算數。 |
| **G8** | `keel-finish` Part 3 | 選哪種整合方式——選 discard 的話還要逐字打出那個字。 |
| **G9** | 任何階段 | repo 之外的不可逆操作：部署、對非暫時性資料庫做 migration、刪資料、對外發布、憑證輪替、push/merge 到受保護分支。指名目標與確切指令，在動手當下問，**就算計畫裡已經寫了也要問**。 |
<!-- /generated:gates -->

G1–G9 不是「檢查點」。每一條都是「沒等到你的答案就繼續，會跳過硬性關卡或做出無法復原的事」的位置——所以這張表反過來也是封閉的：不在表上的「要繼續嗎？」一律禁止。


**G4 按依賴前緣分批，不是死板一次一題（借用 mattpocock batch-grill-me 的做法）。** 大部分發現彼此根本不相依賴，死板逐題只是安全但慢。改成先畫出哪個決定要等哪個決定先答（比如「用哪種登入方式」會決定「session 怎麼存」），再分輪處理。**前緣**指所有前提都已解決、現在就答得出來的發現——把整個前緣塞進**一次** `AskUserQuestion` 呼叫（它原生上限一次 4 題；前緣超過 4 條就拆成最少次數的呼叫）。每輪答完先套用到計畫檔再算下一輪前緣——一個答案常常會順便解掉或改變後面的問題。答案還依賴這輪某條未答問題的，就留到下一輪——分批的界線是依賴關係，不是圖方便。前緣清空就結束。

### 回退路由——後面發現前面錯了怎麼辦

<!-- generated:routes — structure from tables/routes.tsv; run tables/render.sh after editing -->
| 發生什麼 | 從哪個階段 | 退回哪個階段 |
|---------|-----------|-------------|
| 執行時發現計畫跟現況不合，而且不是改一個 task 就能收尾的 | `keel-execute` | `keel-plan` |
| 計畫引用的 `Spec Version` 跟現行 spec 對不上 | `keel-execute` | `keel-plan` |
| 計畫審查完整跑到第 3 遍還沒共識——代表計畫在跟 spec 打架 | `keel-plan-review` | `keel-discover` |
| `keel-finish` 查證據時，某個宣稱怎麼都拿不出證明 | `keel-finish` | `keel-debug` |
| debug 到最後發現，根本是需求本身就錯了 | `keel-debug` | `keel-discover` |
| 已上線的東西，`## Signals` 顯示沒效——是需求錯了，不是程式錯 | 上線後的真實回饋 | `keel-discover` |
| 某階段的 INPUT 契約無法滿足 | 任何階段 | 欠交那份產物的階段 |
<!-- /generated:routes -->

### 建議路由（`keel-workflow` 怎麼判斷）

| 看到什麼訊號 | 走哪 |
|------------|------|
| 想法很模糊、需求還沒講清楚 | `keel-discover` |
| spec 已經有了，後面是好幾步的活 | `keel-plan` |
| 計畫規模大或風險高（超過 8 個檔案、動新架構、碰正式環境資料） | `keel-plan-review` |
| 計畫寫好了而且直觀好懂 | `keel-execute` |
| 準備說做完了、要開 PR 了 | `keel-finish` |
| bug、測試掛掉、行為不如預期 | [`keel-debug`](skills/keel-debug/SKILL.md)——loop 優先：沒有紅燈重現指令就不准開始猜原因 |
| UI / 視覺相關工作 | 交給你自己的設計 skill 路由 |

### 不同專案類型該怎麼配

哪些階段要跑、哪些審查視角要開、上面還要疊什麼——**web app、API、CLI、MCP server、serverless、文件 repo、爬蟲**都有講：見 **[PROJECT-TYPE-GUIDE.md](PROJECT-TYPE-GUIDE.md)**。Backend API 型別現在新增 contract-first 的 OpenAPI/AsyncAPI Task 0；有正式部署環節的 Serverless/edge 型別新增 Release Runbook，在 `keel-finish` 階段產出。

### 領域 skill 怎麼疊上去

要用哪個領域 skill，這件事在**規劃階段**就該定好，因為那時候才看得到全局。`keel-plan` 產出的每個 task 都帶一個 `Skills:` 欄位，寫清楚 implementer 動工前該先叫哪些領域 skill（視覺相關的任務對應 UI 設計 skill、平台相關的任務對應 Cloudflare/MCP 那類平台 skill）。`keel-execute` 會把這欄直接塞進每個 implementer 的工作說明裡，不用臨場現找。

## Subagent 名冊

這條 pipeline 每次派工都指名道姓，指定具體的 `subagent_type`——絕不丟給通用的 `general-purpose` 打混。名字本身就講清楚是哪個階段、哪個角色；模型跟工具權限都寫死在 frontmatter 裡，不會像散文式的提醒（「這裡記得用 opus」）那樣講一講就被忘光。

**唯讀是靠工具權限卡死的，不是靠散文交代。** 視角、懷疑者、designer、researcher 只拿到 `Read, Grep, Glob`（加上各自需要的檢索工具）——**完全沒有 shell**，所以唯讀是「它手上就沒有那個能力」而不是「它答應不做」。三隻 `keel-exec-reviewer-*` 額外拿到 `Bash`，因為審 diff 非得跑 `git diff` 不可；各自在定義檔裡把 shell 限制成唯讀指令，那是比較弱的保證，也正是權限只放到這裡為止的原因。只有 implementer 跟 fixer 有 `Edit`/`Write`。這樣「審查的人不准動自己在審的程式碼」就是規則卡死的，不是提示詞寫寫就算了。

<!-- generated:roster — structure from tables/agents.tsv; run tables/render.sh after editing -->
| subagent_type | 階段 | 幹嘛的 | model | 工具權限 |
|---|---|---|---|---|
| `keel-discover-designer` | 1 探索 | 三個平行方案之一，各自守著不同限制想 | sonnet | 唯讀 |
| `keel-plan-lens-ceo` | 3 審查 | 這件事到底該不該做，還要上網先查有沒有人做過、有沒有人撞過牆 | **opus** | 唯讀 + tavily、exa、context7 |
| `keel-plan-lens-design` | 3 審查 | 使用者看得到的每個狀態都想到了沒（只在 UI 相關計畫才會開） | sonnet | 唯讀 |
| `keel-plan-lens-eng` | 3 審查 | 照這樣寫真的做得出來嗎，還要查一下用到的 API 是不是早就被棄用了 | sonnet | 唯讀 + context7、Ref |
| `keel-plan-lens-security` | 3 審查 | 設計期做 STRIDE 威脅建模（只在命中 2+ 資安詞彙、有高風險標記、或新增對外端點時才會開） | **opus** | 唯讀 |
| `keel-plan-lens-dx` | 3 審查 | 開發者要花多少力氣才能上手（只在面向 API/CLI/SDK 的計畫才會開） | sonnet | 唯讀 + context7 |
| `keel-plan-skeptic` | 3 審查 | 挑一條 High 等級的發現來反駁——單點查證就搞得定的那種 | sonnet | 唯讀，**不給它上網查** |
| `keel-plan-skeptic-critical` | 3 審查 | 反駁 Critical 等級、碰到安全/資料遺失/不可逆操作、或要跨檔案推理才能判斷的發現 | **opus** | 唯讀，**不給它上網查** |
| `keel-exec-implementer` | 4 執行 | 把一個 task 做出來，強制測試先行 | sonnet | 完整權限 |
| `keel-exec-reviewer-spec` | 4 執行 | 只看有沒有照規格做 | sonnet | 唯讀 + shell 僅限 `git diff`/`log`/`show`、`which`、既有測試指令 |
| `keel-exec-reviewer-quality` | 4 執行 | 只看寫得好不好 | sonnet | 唯讀 + shell 僅限 `git diff`/`log`/`show`、`which`、既有測試指令 |
| `keel-exec-reviewer-security` | 4 執行 | 只看資安軸——命中 R4 條件才會派工 | **opus** | 唯讀 + shell 僅限 `git diff`/`log`/`show`、`which`、既有測試指令 |
| `keel-exec-fixer` | 4 執行 | 只修拿到手的那幾條發現，不順手改別的 | sonnet | 完整權限 |
| `keel-exec-fixer-critical` | 4 執行 | 只在修復迴圈第 4-5 輪出手——標準層卡了兩次才輪到它 | **opus** | 完整權限 |
| `keel-wayfind-researcher` | 前置階段 | 解一張能靠外部資料查出答案的研究票 | sonnet | 唯讀 + 完整檢索工具 |
| `keel-auditor` | 後設 | 用突變攻擊這個 repo 自己的檢查機制，找沒人編碼過的缺陷類別 | **opus** | 唯讀 + shell 僅限跑檢查與突變套件；突變只在拋棄式副本做，絕不 commit |
<!-- /generated:roster -->

`keel-exec-reviewer-spec` 會依「合約測試證據強度」分級每一條 Interface drift 發現（有既有測試 > 只寫了合約描述 > 未經查證的宣稱），不是照計畫怎麼寫就照單全收。

另外還有六個本 repo 不附、但會依名字派工的 agent（`planner`、`code-reviewer`、`test-engineer`、`silent-failure-hunter`、`build-error-resolver`、`security-auditor`）——它們的模型與工具由你的安裝決定，所以上面那張表釘不住，pipeline 該用的時候會直接用原名派出去：`test-engineer`、`silent-failure-hunter`。`security-auditor` 是另一路的即興專家——只在你手動叫 `/security-review` 或 `/ship` 時才會出場，`keel-plan-review`、`keel-execute` 從來不會自動派它；這兩個階段自己的資安把關現在交給 `keel-plan-lens-security`（第 3 階段）跟 `keel-exec-reviewer-security`（第 4 階段第三軸）。`keel-execute` 收尾時的整分支審查用 `code-reviewer`，而且**故意不去指定它的模型**——讓它自己繼承這次 session 裡最強的那顆模型，因為這是 `keel-finish` 之前的最後一道防線，不能省。

### 分層靠 agent 名字，不是靠 model 參數

想讓懷疑者省點力氣、簡單的發現用便宜模型審，最直覺的做法是照嚴重度在派工時傳個 `model` 參數去覆寫。這條 pipeline 就是刻意不這麼幹——用參數決定模型，這個決定會埋在一行函式呼叫裡，進度畫面上完全看不出來，時間一趕就容易被忘記。（這條 pipeline 早期版本剛好就有過這種「記得要做 X」的散文規則，事後稽核發現根本沒有人真的照做過。）

所以改成讓「用哪一層」直接等於「派哪個 agent」：

- `keel-plan-skeptic`（sonnet）處理單點查一下就能定案的發現——引用的那行到底存不存在、講的是不是真的那回事。
- `keel-plan-skeptic-critical`（opus）處理 Critical 等級、碰到安全/資料遺失/不可逆操作的發現，或者需要跨檔案推理才能判斷的（追蹤呼叫者、找有沒有既有防護、估影響範圍多大）。
- 標準層可以直接回一個 `ESCALATE`，不硬撐超出自己能力範圍的判斷——控制器收到就會改派重案層去查。`ESCALATE` 本身絕不算一個裁決。
- **不確定就升級，別猶豫。** 這裡代價不對等：懷疑者誤殺一條真的很重要的發現，等於讓一個缺陷直接闖過執行階段跑到正式環境；懷疑者誤放過一條弱發現，頂多多花一輪修復再審。pipeline 骨子裡本來就偏向「證據不夠就反駁掉」，model 層級是攔在這個偏向跟真正犯錯之間唯一的防線。

`keel-execute` 的修復迴圈用的是同一套邏輯（從 superpowers 6.2.0 移植過來）：第 1-3 輪都給標準層 `keel-exec-fixer`（sonnet）重試；到第 4-5 輪改派全新一次的 `keel-exec-fixer-critical`（opus）——同樣的脈絡、同樣的模型已經失敗兩次了，第三次照舊做法不會突然成功。撐到第 5 輪還有發現沒修完，斷路器就跳：會壞事的（破壞 Delivers 行為、安全、資料完整性）直接擋下來丟給使用者，無傷大雅的就記進帳本附裁決繼續往下走。這條 pipeline 裡沒有任何一處是靠傳 `model` 參數升級的——要升級，就開一個新名字的 agent。

### 先驗掃描——動工前先查有沒有人早就做過、早就撞過牆

CEO 視角（`keel-plan-lens-ceo`）動任何內部推理之前，先強制上網掃一輪：搜尋看有沒有現成的產品或函式庫、查有沒有人早就踩過這個坑、翻文件確認某個框架是不是本來就內建這功能。輸出分三段——現成方案、已知撞牆、還有一個能講出「即便如此還是值得做」的**具體差異點**。

第三段刻意設成硬性關卡：一條先驗發現如果講不出跟我們情況具體差在哪，信心分數就會被壓低，而且**永遠不能單靠這條就砍掉整個計畫**，也不能升級成 User Challenge。名字聽起來撞衫不代表真的重複，如果只憑一個表面比對就殺掉一個正當的計畫，那會是這個視角能犯的最貴的錯。

Eng 視角（`keel-plan-lens-eng`）跑另一輪平行檢查，對照現行文件確認計畫裡點名的每個框架/函式庫/API，從寫計畫到現在有沒有被棄用或砍掉。

**每條外部發現都要附 URL、查證日期、逐字引用**——跟這條 pipeline 對內部 `file:line` 引用一直以來的要求一樣嚴。抓回來的網頁內容一律當成不可信的東西：裡面藏的任何指令一概不理，只挑事實出來用。

### 扇出上限

沒有哪個階段可以無限開 agent。上限是**同時最多 8 個，總量每個 task loop 最多 16 個**（keel-plan-review 是每輪最多 8 隻 skeptic）；真的超過的話，pipeline 會按嚴重度排序，先蓋前面幾條，剩下的**一定要**印出 `SKIPPED: <幾條> — <原因>`。悄悄少做卻不講，這條 pipeline 當成 bug 處理——一個階段偷偷只查了六成卻回報得像查了十成，比一開始就沒跑還糟糕。

Fan-out ceiling: ≤8 concurrent, ≤16 total per task loop.

## 來源出處與跟上游同步

這是**合成出來的東西，不是 fork**——上游還在持續改。每個 SKILL.md 的 frontmatter 都寫了來源跟版本號。合成時的版本快照（2026-07-14 合成；2026-07-30；discover 階段先驗掃描與 design lens 的視覺／路由檢查 2026-08-10 加了 subagent 名冊跟先驗掃描）：

| 上游 | 版本 | Repo |
|------|------|------|
| superpowers | 6.1.1 | [obra/superpowers](https://github.com/obra/superpowers) |
| gstack | 1.60.1.0 | [garrytan/gstack](https://github.com/garrytan/gstack) |
| planning-with-files | 3.5.0 | [OthmanAdi/planning-with-files](https://github.com/OthmanAdi/planning-with-files) |
| mattpocock/skills | 沒版號的 monorepo——照 commit 對，不是照 tag | [mattpocock/skills](https://github.com/mattpocock/skills) |
| keel-security-review 需求書（2026-08-07） | 內部文件，非 repo | 資料來源：STRIDE 威脅建模、OWASP Top 10:2025、Veracode 2025 GenAI report、slopsquatting 研究 |
| keel-workflow SDD 元素整合需求書（2026-08-07） | 內部文件，非 repo | 資料來源：外部分享的 SDD/Contract-first/ADR 流程比對 |

要跟上游同步的話：

1. 對照上表版本號，看上游是不是出新版了。
2. 讀它們的 changelog，只挑**機制**上的改動來看（新關卡、新流程之類）。純粹改寫文字、或是修這個 repo 本來就刻意丟掉的東西（Codex hook、遙測、mockup board），不用理。
3. 把機制上的改動搬進受影響的那個階段 skill，順手把它 frontmatter 裡的版本號往上調。

如果你手上同時裝著上游原版，該用重量級原版的時候就用——比如超過 15 個檔案的大計畫，用 gstack `/autoplan`（雙模型互相對照）；要開 GitHub issue 的話用 gstack `spec`。

## 設計原則

- **是蒸餾，不是硬拼在一起**——一個機制能留下來，是因為它真的扛得住重量，不是因為它本來就存在。
- **關卡是神聖不可侵犯的，產出物可以縮水**——時間趕的時候可以把 spec 寫短一點，但核准這一步絕不能跳過。
- **證據比報告可信**——subagent 說「成功了」、一次過期的測試結果、「應該沒問題」，這些都不算證據；diff 跟剛跑出來的指令輸出才算。
- **檔案系統比 context window 靠得住**——只要是要撐過壓縮還在的東西，就寫進檔案裡。
- **具名 agent 比散文提醒可靠**——規則真的重要的話（「這裡要用強模型」、「這隻不准寫檔」），就寫死在被派工那隻 agent 的 frontmatter 裡，不要只寫一句話指望以後有人會記得。

## 想貢獻的話

歡迎開 issue、發 PR——特別是回報這個 repo 還沒跟上的上游機制變化，或是實際用下來發現某個階段/關卡/agent 其實沒撐住的情況。動手前先看一眼上面的設計原則：貢獻應該是蒸餾出更好的東西，不是幫 pipeline 已經有的功能再開一條第四種做法。

## 授權

[MIT](LICENSE)
