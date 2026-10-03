# keel

**給 Claude Code 用的五階段開發流程。每個階段一個 skill，每個角色都叫得出名字，該卡關的地方一定卡住。**

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

`keel-workflow` 是五個階段上面的總機：判斷這次的請求該進哪個階段、派對應的 skill 去做，還會做一件大部分路由器不做的事——後面的階段發現前面搞錯了，它知道要把工作**退回去**。

## 你會得到什麼

- **只有一條主線。** 每個階段一個 skill，不用在四種「做計畫」的工具之間挑。小事直接開工，只有大案或高風險的計畫才走審查。
- **只在該問的地方問你。** 會停下來等你回答的只有九個具名關卡。跑一下就知道答案的事，它自己查，不拿來問你。
- **「做完了」要拿得出畫面。** 每個宣稱都要剛跑出來的證據；一開始就指名的關鍵流程，要透過 commit 在 repo 裡的驗證工具實際跑一遍，不是 agent 自己說好就好。
- **審查沒辦法放水。** 每個 task 配二到三個互相看不到彼此結論的審查者；計畫審查裡的高嚴重度發現，還要先撐過一個專門負責反駁的懷疑者。
- **越用越懂這個專案。** 學到的教訓先想辦法寫成程式結構或 lint 擋住，擋不住才寫進專案規則庫，下一份計畫會讀到。

## 安裝

把 `skills/` 跟 `agents/` 放到 Claude Code 會讀的地方：

```bash
# 只裝這個專案用
cp -R skills/* your-repo/.claude/skills/
cp -R agents/* your-repo/.claude/agents/

# 或全域裝一次到處用
cp -R skills/* ~/.claude/skills/
cp -R agents/* ~/.claude/agents/
```

`agents/` 可以不裝，但強烈建議裝——不裝的話，每次派工都會悄悄退回內建的 `general-purpose`：模型沒釘死、工具權限沒鎖、進度畫面也看不出現在是誰在跑。

裝完重開一次 Claude Code（新的 skill／agent 目錄要重啟才會讀到）。不用建置、不用掛 hook、不用裝套件。

## 怎麼用

```text
# 從一個模糊的想法開始
/keel-discover 我想幫公開 API 加 rate limiting

# 需求已經很清楚了
/keel-plan 幫報表頁加 CSV 匯出，spec 在 docs/specs/...

# 計畫很大，或動到正式環境的資料
/keel-plan-review

# 準備好了，開工
/keel-execute

# 講「做完了」之前先跑這個
/keel-finish

# 懶得判斷就直接講任務，讓總機自己分流
/keel-workflow 幫管理後台加 OAuth 登入
```

每個階段做完會自己宣告下一站、直接交接。子 agent 一回來就用它的名字播報結果，不會讓你對著一片安靜的畫面猜四個 agent 在幹嘛。

## 五個階段

| # | Skill | 把什麼變成什麼 | 保證什麼 |
|---|-------|--------------|---------|
| 1 | [`keel-discover`](skills/keel-discover/SKILL.md) | 模糊想法 → 你核准的 spec | 沒核准不准寫程式。問問題之前先拿 `path:line` 證據；repo 內外都做先驗掃描；在這裡就指名一到三條**關鍵流程**，每條都要跨過真實的整合邊界。 |
| 2 | [`keel-plan`](skills/keel-plan/SKILL.md) | spec → 不懂這個 codebase 的人也能照做的計畫 | 禁止空話佔位。每個 task 寫明交付什麼、動哪些檔、介面長怎樣、該叫哪些領域 skill。關鍵流程要寫成可執行的 `Drive` 指令，透過 commit 在 repo 裡的驗證工具跑；repo 還沒有這種工具，第一個 task 就先做出來。 |
| 3 | [`keel-plan-review`](skills/keel-plan-review/SKILL.md) | 粗計畫 → 審過的計畫 | CEO、Eng 一定跑，Design、Security、DX 視情況開。例行的自己拍板，要判斷的才問你，而且按依賴關係分批問；跑個小實驗就能分出高下的，先跑再說。 |
| 4 | [`keel-execute`](skills/keel-execute/SKILL.md) | 計畫 → 能跑的程式 | 每個 task 一個強制測試先行的 implementer；規格、品質兩軸審查（命中條件再加資安軸），絕不混成一個裁決；斷線也不會掉資料的進度帳本；沒有 subagent 時有 inline 備援。 |
| 5 | [`keel-finish`](skills/keel-finish/SKILL.md) | 「好像做完了」→ 合併進去 | 每個宣稱都要新鮮證據、每條關鍵流程都要跑過、Success Criteria 由你當場核對、散落的未決事項收攏、教訓回寫，最後照你選的方式整合分支。 |

**旁線**，對得上才會進：

| Skill | 什麼時候用 |
|-------|----------|
| [`keel-wayfind`](skills/keel-wayfind/SKILL.md) | 工作大到一個 session 做不完、路線又還看不清楚——先畫一張決策票地圖，一個 session 解一張。 |
| [`keel-debug`](skills/keel-debug/SKILL.md) | 東西壞了、原因不明——沒有紅燈重現指令之前不准開始猜。 |
| [`keel-audit`](skills/keel-audit/SKILL.md) | 你明確要求對整個程式碼庫做資安稽核。原樣收錄 Cloudflare 的 security-audit 方法（MIT），只讀原始碼、帶覆蓋率帳本、每個候選配一個全新的驗證者。主流程絕不會自己走進來。 |

web app、API、CLI、MCP server、serverless、文件 repo、爬蟲各該跑哪些階段、開哪些視角，寫在 **[PROJECT-TYPE-GUIDE.md](PROJECT-TYPE-GUIDE.md)**。

## 什麼時候會停下來等你

### 關卡——唯一會停下來等你回答的地方

除了這些，其他地方都不會問你要不要繼續：

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

這張表反過來也是封閉的：不在表上的「要繼續嗎？」一律禁止。G4 會把前提都已經定案的問題一次問完（最多四題），答案套用之後再算下一批——分批看的是依賴關係，不是圖方便。

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

## 怎麼確保做出來的東西是真的

- **證據比報告可信。** subagent 說「成功了」、過期的測試結果、「應該沒問題」都不算；diff 跟剛跑出來的指令輸出才算。
- **關鍵流程提早跑。** 在探索階段指名、規劃階段寫成指令、執行階段一跑得動就跑。指令要透過 commit 在 repo 裡的**啟動器**（一個指令把產品啟動到已知狀態，再把證據存下來）跟**功能地圖**（每個功能怎麼走到、按哪裡、該看到什麼），使用者丟來一張模糊截圖，也找得到地方去查。
- **審查軸互相獨立。** 規格對不對、寫得好不好分開審；審查者先讀測試再讀實作，而且要講出「會怎麼壞」，不能只指出哪一行。PASS 的意思是這個 diff 讓程式碼更健康，不是完美。
- **註解要有理由才准留。** diff 新加的註解，只有授權聲明、外部依賴逼出來的怪行為、公開 API 契約、issue 或規格連結、不直觀的演算法這幾種能留。替權宜寫法找藉口的註解，直接當成沒修好的問題處理；只寫在註解裡的限制，要改成型別、測試或 lint。
- **關卡不能跳，產出物可以縮。** 趕時間就把 spec 寫短，核准絕不跳過。

## 怎麼越用越聰明

AI 會照它看到的寫法繼續寫，所以程式碼庫本身就是它的記憶。每次糾正 AI，keel 都會問一句：這個教訓該放哪裡？由強到弱：

1. **讓錯的寫法根本寫不出來**——用型別、結構、API 的形狀擋住。
2. **一跑就會失敗的檢查**——lint、編譯器設定、CI。
3. **專案規則庫裡的一條規則**——下一份計畫的派工單會讀到。
4. **靠人在審查時記得**——最弱，最後才用。

`keel-finish` 會把 `.keel/findings.md` 裡的教訓照這個順序往下推，前兩層都擋不住的才寫成規則。審查抓到的壞寫法，會到整個 repo 搜一次：別處也有的話，回報數量和位置，先提議擋住不讓它再擴散，再排清理。延後的工作寫進專案 backlog，附一個下一階段查得到的連結。規則庫分兩層：本地的記「這個專案這一行該怎麼寫」，跨專案的記「會改變你怎麼設計」的做法。

## Subagent 名冊

每次派工都指名道姓用具體的 `subagent_type`，絕不丟給通用的 `general-purpose`。名字前綴是階段、後半是角色；每隻 agent 的 frontmatter 釘死模型、鎖住工具，不會像散文提醒（「這裡記得用 opus」）那樣講一講就忘了。

**唯讀靠工具權限卡死，不是靠提示詞交代。** 視角、懷疑者、designer、researcher 和兩隻稽核 agent 只有 `Read, Grep, Glob`（加上各自需要的檢索工具），完全沒有 shell。三隻 `keel-exec-reviewer-*` 另外拿到 `Bash`，因為審 diff 一定要跑 `git diff`；各自在定義檔裡把 shell 限制住，這是比較弱的保證，也是權限只放到這裡的原因。只有 implementer 跟 fixer 能改檔。

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
| `keel-audit-hunter` | 旁線 | 整庫稽核：偵察、每隻獵捕一個覆蓋單元、覆蓋評審——只讀原始碼 | sonnet | 唯讀，**不給 shell** |
| `keel-audit-verifier` | 旁線 | 每個稽核候選一個全新驗證者：confirmed、needs_validation（不給嚴重度）或 rejected | **opus** | 唯讀，**不給 shell** |
| `keel-auditor` | 後設 | 用突變攻擊這個 repo 自己的檢查機制，找沒人編碼過的缺陷類別 | **opus** | 唯讀 + shell 僅限跑檢查與突變套件；突變只在拋棄式副本做，絕不 commit |
<!-- /generated:roster -->

另外有五個會依名字派工、但本 repo 不附的 agent，模型跟工具由你的安裝決定：`planner`、`code-reviewer`（收尾的整分支審查，刻意不指定模型，讓它繼承這次 session 最強的那顆）、`test-engineer`、`silent-failure-hunter`、`build-error-resolver`。`security-auditor` 是另一路的專家，pipeline 從不派它；這條 pipeline 自己的資安把關在 `keel-plan-lens-security` 跟 `keel-exec-reviewer-security`。

**分層靠換 agent，不靠 model 參數。** 想讓簡單的發現用便宜模型審，做法是派另一隻 agent（`keel-plan-skeptic`），不是對同一隻傳 `model` 覆寫——這樣用了哪一層在進度畫面上看得到，時間一趕也不會忘。標準層判斷不了就回 `ESCALATE`，不硬撐；拿不準就升級，因為誤殺一條真的 Critical 會讓缺陷一路闖到正式環境，誤放一條弱發現頂多多修一輪。修復迴圈也一樣：第 1–3 輪用 `keel-exec-fixer`，第 4–5 輪換全新的 `keel-exec-fixer-critical`，第 5 輪還沒修好就跳斷路器。

**動工前先查有沒有人做過。** CEO 視角會上網查現成方案、已知撞牆的例子，以及「即便如此還是值得做」的具體差異點；講不出差異點的比對，不能拿來砍掉計畫。Eng 視角會對照現行文件，確認計畫點名的 API 還在。每條外部發現都要附 URL、日期、逐字引文，抓回來的網頁一律當不可信的輸入。

### 扇出上限

沒有哪個階段可以無限開 agent。超過上限時，pipeline 會按嚴重度排序、先蓋前面幾條，剩下的**一定要**印出 `SKIPPED: <幾條> — <原因>`——偷偷只查了六成卻回報得像查了十成，比一開始就沒跑還糟。

Fan-out ceiling: ≤8 concurrent, ≤16 total per task loop.

## keel 怎麼測它自己

提示詞沒有編譯器，所以 [`eval-fixtures/`](eval-fixtures/) 用 keel 檢查 keel：

```bash
bash eval-fixtures/check-structure.sh    # 檢查檔案層面的事實；exit 0 = 全過
bash eval-fixtures/run-mutations.sh      # 證明上面每條檢查真的會變紅
bash tables/render.sh                    # 重新生成三張共用的表
```

- `check-structure.sh` 驗腳本驗得了的事：每隻 agent 都釘了模型和工具清單、沒有唯讀 agent 拿到寫入權限、每個派工名稱都找得到定義、fixture 逐字引用規則原文、安裝版跟 repo 一致。
- `run-mutations.sh` 把歷次稽核找到的缺陷一個一個塞進拋棄式副本，確認指定的檢查會變紅。沒有任何突變測過的檢查，會讓整輪失敗。
- **出現在多份檔案裡的規則只有一份正本**，放在 [`rules/`](rules/)，用位元組比對。只改其中一份就會失敗。
- **名冊、關卡、回退路由三張表是生成的**，來源在 [`tables/`](tables/)，寫進每一份用到它的文件。
- `NN-*.md` 情境 fixture 涵蓋腳本判斷不了的邊界；`RULE-INVENTORY.md` 列出每條規則在哪裡執行、靠什麼驗證——刻意不給覆蓋率百分比。

這份 README 刻意不寫數量；檢查器每次跑都會印出來，寫死的數字已經過期過兩次。

## 來源與跟上游同步

這些是**合成出來的，不是 fork**。每份 `SKILL.md` 的 frontmatter 都記了來源跟版本。

| 上游 | 版本 | 貢獻了什麼 |
|------|------|----------|
| [obra/superpowers](https://github.com/obra/superpowers) | 6.1.1 | 各階段骨幹：brainstorming、writing-plans、subagent-driven development、verification-before-completion |
| [garrytan/gstack](https://github.com/garrytan/gstack) | 1.60.1.0 | autoplan 的決策分類、審查視角、證據閘門 |
| [OthmanAdi/planning-with-files](https://github.com/OthmanAdi/planning-with-files) | 3.5.0 | 檔案系統當記憶體、進度帳本 |
| [mattpocock/skills](https://github.com/mattpocock/skills) | 沒有版號，照 commit 同步 | 垂直切片任務、分批追問、同一問題想兩套、詞彙表紀律 |
| [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill) | `c1c8a8c` | `keel-audit` 整套方法，MIT 授權原樣收錄 |
| Lauren Tan 在 Cursor Compile 2026 的講題與 [pstack](https://github.com/cursor/plugins/tree/main/pstack) | 2026-10 | 註解規則、先擋住再寫規則、驗證工具、能查就不問、壞寫法擴散檢查 |
| keel-security-review 需求書（2026-08-07） | 內部文件 | STRIDE、OWASP Top 10:2025、Veracode 2025 GenAI report、slopsquatting 研究 |

同步方式：對照上表版本看上游有沒有新版，只把**機制**上的改動（新關卡、新流程）搬進受影響的 skill，再調高它 frontmatter 裡的版本。純改寫文字、或修這裡本來就刻意丟掉的東西（Codex hook、遙測、mockup board），不用理。超過 15 個檔案的大計畫、又剛好裝了 gstack，就直接用它的 `/autoplan`。

## 設計原則

- **蒸餾，不是硬拼**——一個機制能留下來，是因為它真的扛重量，不是因為它本來就存在。
- **關卡不能跳，產出物可以縮**——spec 可以寫短，核准不能跳。
- **證據比報告可信**——看 diff 跟剛跑出來的輸出，不聽「應該沒問題」。
- **檔案系統比 context window 靠得住**——要撐過壓縮的東西就寫進檔案。
- **結構比散文可靠**——規則真的重要，就寫進 agent 的 frontmatter、型別或檢查裡，不要只寫一句話指望有人記得。

## 想貢獻的話

歡迎開 issue、發 PR——特別是這裡還沒跟上的上游機制改動，或實際用下來發現某個階段、關卡、agent 其實沒派上用場。貢獻應該是蒸餾出更好的做法，不是替 pipeline 已經有的功能再開第二條路。

## 授權

[MIT](LICENSE)
