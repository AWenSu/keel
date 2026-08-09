# Plan: keel-workflow SDD 元素整合（ADR 提前／UAT 顯式化／Contract Test／功能矩陣／API-heavy 與部署類型預設）

> **For agentic workers:** execute with keel-execute.

**Goal:** 把外部「功能矩陣＋ADR＋SDD＋Contract-first＋TDD／Contract Test＋
E2E／UAT＋Release Runbook」流程中，本 pipeline 目前缺或偏弱的項目整合進
`keel`：6 項既有缺口強化（R1-R6）＋ SDD 三項具體機制
（spec 溯源、結構化驗收、核准閘門——既有 keel-plan 只有 spec-first 精神，
缺這三個機制本體）。

**Spec:** `/Users/wen/myProject/Claude/20260807_2214_keel-workflow-sdd-integration-requirements.md`

**Architecture:**
```
keel-discover           keel-plan              keel-plan-review           keel-execute                keel-finish
 + Status:draft/     + 功能矩陣產出(R4)  →  + ADR 產出於 Step5(R1) →  + Interfaces 一致性       + Part2 UAT 顯式核對(R2)
   approved 欄位      + Given-When-Then      Design lens 沿用          檢查(R3, spec 軸內)      + Part2 ADR skip-note(R1)
   (SDD 核准閘門)       驗收格式(SDD)                                                            + Release Runbook(R6)
                     + Spec Version 欄位
                       (SDD 溯源)

keel-workflow                              PROJECT-TYPE-GUIDE.md
 + Backward route: spec 改動不符 plan       + API-heavy 型 contract-first 細節(R5)
   記錄版本 → 退回 keel-plan(SDD)             + 部署型 Release Runbook 細節(R6)
```
全部是既有 7 份 skill/agent 檔＋1 份專案類型指南＋雙語 README 的接線與
強化變更。無新增 agent、無新增外部服務、無 runtime 程式碼變更 —— 全部是
prompt/skill 定義檔的文字修改。

**Global Constraints（逐字抄自 spec，勿改寫）：**
- 不新增外部強制工具依賴 —— R3/R5 提及的 Spectral/Pact 等工具，比照既有
  gitleaks/semgrep 模式，工具不存在時誠實回報「未執行」，不擋 pipeline
- R1/R2 為既有機制的位置調整與顯式化，禁止重複定義 ADR/Success-Criteria
  邏輯本體，只改觸發時機與可稽核性
- R4/R5 共用「命中 UI/多角色關鍵字」與「命中 API-heavy 專案類型」這兩個
  既有判準機制，不得另造第三套關鍵字偵測規則
- 每一項改動需同步 `README.md` 與 `README.zh-TW.md` 的 roster／流程說明，
  並比照既有慣例更新 provenance 表格
- 每一項改動需比照既有 agent/skill 檔案，propagate 到 `~/.claude/skills/`
  與 `~/.claude/agents/` 對應的 live 安裝副本

**Success Criteria（抄自需求書）：**
- [ ] `keel-plan-review/SKILL.md` Step 5 含 ADR 產出邏輯，keel-finish Part 2
      標註「若已於 Step 5 處理則略過」
- [ ] `keel-finish/SKILL.md` Part 2 含使用者當場核對 Success Criteria 的
      顯式步驟
- [ ] `keel-exec-reviewer-spec.md` 含 Interfaces block 一致性檢查項，工具
      存在時使用、不存在時退回純比對並誠實回報
- [ ] `keel-plan/SKILL.md` 含功能矩陣產出規則，觸發判準沿用既有 UI 關鍵字
      機制
- [ ] `PROJECT-TYPE-GUIDE.md` 的 Backend API 型含 contract-first 細節
      (R5)、新增或擴充部署相關型別含 Release Runbook 細節 (R6)
      （偏離說明：需求書字面寫「新增 API-heavy 類型」，Task 5 判斷併入既有
      Backend API 型比新增第三型更 DRY，此為刻意偏離，非改寫疏漏——Eng
      lens 覆核後判斷工程取捨合理，記錄於此供稽核）
- [ ] 兩份 README 的 roster/流程/provenance 皆同步更新
- [ ] 所有改動的 live 安裝副本與 repo 副本 diff 一致
- [ ] spec 未核准（`Status: draft`）時 `keel-plan` 回傳 BLOCKED 退回
      keel-discover；spec 核准後 Success Criteria 採 Given-When-Then 格式；
      plan 執行期間 spec 版本與 plan 記錄不符時，`keel-workflow` Backward
      routes 命中退回 keel-plan

## Provenance ＋ 未驗證項（CEO lens 要求）

「功能矩陣＋ADR＋SDD＋Contract-first＋TDD／Contract Test＋E2E／UAT＋
Release Runbook」為外部單一來源口頭分享，未附連結／文件，本計畫的
R1-R6 是與現有 pipeline 比對後取的差異項，未對來源流程本身的成效做
外部驗證（無案例研究、無 benchmark）。各項證據強度：
- R1（ADR 提前）／R2（UAT 顯式化）：純位置調整＋顯式化既有機制，
  不依賴來源流程成效，證據強度視為高（内部邏輯自洽即可）
- R3（Contract Test）／R4（功能矩陣）：外部常見實踐，非本次來源獨有，
  證據強度中——採漸進式（工具存在才用、不存在退回文字比對），失敗
  成本低
- R5/R6（Contract-first／Release Runbook）：條件式套用，未命中判準的
  專案完全不受影響，即使來源方法論本身未經驗證，本計畫的風險隔離
  設計已把潛在成本封在極小範圍
- Task 6（SDD 三機制）：使用者於本次 review Step 0 明確追加授權（見
  下方「使用者授權變更記錄」），非需求書原始範圍——CEO lens 曾標記此
  為 Critical「範圍外」finding，但這是流程正確運作的結果（Step 0
  premise 修正），非計畫自行擴權，記錄於此供稽核，不視為未決問題

**使用者授權變更記錄：** 本計畫最初的需求書（20260807_2214 requirements）
明文排除 SDD 強化（「SDD 精神本身已由 keel-plan 覆蓋，不另立項」）。
keel-plan-review Step 0 premise 確認時，使用者明確答覆「不覆蓋，但要增加
其優點」，並於後續澄清問題答覆「三項都要，合併成一個 task」——這是
Task 6 存在的直接授權來源，優先於需求書原文。

**Alternatives considered（keel-discover 慣例，補記於此因本計畫走
lightweight 路徑未經完整 keel-discover）：**
1. 全部 R1-R6 + SDD 三機制打散成多個小計畫分批審查——否決：7 個
   task 互相依賴少，拆分只會增加多輪 review 的協調成本，不減風險
2. SDD 三機制不做，只做 R1-R6——否決：使用者已於 Step 0 明確追加授權
3. 直接照抄外部分享的流程全套（含完整獨立 Contract-first pipeline、
   獨立 UAT 角色）——否決：本 repo 是 single-user pipeline，外部流程
   假設多角色協作，照抄會引入不存在的協作場景，故只取「機制」不取
   「角色分工」

## 專案類型調整（非標準 TDD）

本專案是 skill 定義檔（純 markdown prompt），無編譯、無 runtime、無既有
測試框架 —— keel-plan 模板的「write failing test / run / implement / run /
commit」五步驟字面上不適用。**採用的驗證取代方案**（對齊本 repo 前次同類
變更的既有作法，見 `13ee5ee`/`da1c82a` 等 commit）：每個 task 的驗證步驟
改為 (a) `grep -c` 確認新增內容確實寫入且未重複、(b) 對照 Success Criteria
逐條手動走一遍新規則的 dispatch 邏輯（例如：拿一個假想的多角色計畫，手動
核對功能矩陣規則是否觸發）。這不是跳過驗證，是把「測試」換成這個專案類型
真正的求證方式。

## Task 1: ADR 決策點提前至 keel-plan-review Step 5   [Risk: Low]

**Delivers:** `keel-plan-review` Step 5 處理 Taste/User Challenge 決策時，
若某決策符合既有判準（難逆＋反直覺＋真 trade-off），當場產出一段 ADR 並
寫入 plan file（或 `docs/adr/` 若存在），而非等到 keel-finish 才第一次被
提及。既有的「Mechanical 自動套用、Taste/Challenge 問使用者」流程本體不變。
**Files:** `/Users/wen/.claude/skills/keel-plan-review/SKILL.md:220-270`
（Step 5 段落，緊接在既有「Apply every answer from a round...」之後，
「After all questions are resolved」之前插入新小節）
**Depends on:** none
**Skills:** none
**Interfaces:**
  - Consumes: 無（沿用 Step 5 既有 Taste/User Challenge 分類與既有 ADR
    判準——難逆＋反直覺＋真 trade-off，這判準文字已存在於 `keel-finish`
    Part 2，逐字抄用不重寫）
  - Produces: ADR 產出時機標記（「此決策已於 Step 5 產出 ADR」），供
    Task 2 的 keel-finish Part 2 判斷是否要 skip

- [ ] 在 `keel-plan-review/SKILL.md` Step 5，Round 逐項處理迴圈中新增規則：
      每個決策套用完成後，立即判斷是否符合 ADR 判準（難逆＋反直覺＋真
      trade-off——逐字抄用 `keel-finish/SKILL.md:92` 現有那句判準，不重寫
      措辭），符合則追加一段 ADR（Context/Decision/Consequence 三段，
      比照 `keel-finish` Part 2 現有格式）寫入 plan file 的新增
      `## ADR: <決策名>` 小節
- [ ] 明確寫出：不符合判準的決策不產出 ADR，這是既有機制的位置提前，不是
      新增一道強制關卡
- [ ] 附註一句：`keel-discover/SKILL.md:170-176` 既有 ADR offer 判準用逗號
      分隔三條件、`keel-finish/SKILL.md:91-92` 用「+」分隔——同一套判準的
      既有措辭分歧（早於本計畫存在），本 task 逐字抄用 keel-finish 的版本，
      不藉此機會統一三處寫法（Eng lens 標記為既有問題，非本輪範圍）
- [ ] `grep -c "^## ADR:" skills/keel-plan-review/SKILL.md` 確認範例／規則
      文字存在且只出現一次（防重複寫入）
- [ ] 手動走查：假想一個「換掉 session 儲存機制」的 Taste 決策（難逆＋反
      直覺＋真 trade-off 三者皆中），核對新規則文字是否明確要求當場產出
      ADR；再走查一個「函式命名選 A 或 B」的 Taste 決策（不符合判準），
      核對新規則文字是否明確排除它
- [ ] 不在此 commit —— 已核實 `~/.claude` 不是 git repo，只是安裝目錄；本
      task 只編輯並用 `diff` 驗證 live 副本，實際 commit 於 Task 7 一次
      完成（同前次 `13ee5ee` 慣例：多任務單一 commit，非逐 task commit）

## Task 2: keel-finish Part 2 — ADR skip-note ＋ UAT 顯式核對   [Risk: Low]

**Delivers:** `keel-finish` Part 2 的既有 ADR offer 邏輯旁註記「若
Step 5 已產出則此處略過，不重複產生」；同時 Part 2 的 Success Criteria
checklist 新增明確步驟——每一條 Success Criteria 由**使用者**當場核對
（非僅 agent 自證通過），把既有隱性假設（single-user pipeline＝使用者即
業主）寫成可稽核的顯式流程步驟，不新增角色機制。
**Files:** `/Users/wen/.claude/skills/keel-finish/SKILL.md:80-93`（Part 2
整段：Success Criteria checklist 段落＋既有 ADR offer 那句）
**Depends on:** Task 1（沿用 Task 1 訂出的「Step 5 已產出 ADR」判斷措辭，
確保兩處文字一致，不各自發明一套說法）
**Skills:** none
**Interfaces:**
  - Consumes: Task 1 產出的 ADR 產出時機標記措辭
  - Produces: 無（Part 2 是既有 stage 的終端強化，無下游 task 消費）

- [ ] 在 `keel-finish/SKILL.md` Part 2 現有「Same check for ADRs」那句後
      加一句：若該決策已於 `keel-plan-review` Step 5 產出 ADR（沿用 Task 1
      訂出的措辭判斷），此處略過，不重複產出
- [ ] 在 Part 2 開頭「Open the plan's Success Criteria checklist」那句後
      新增顯式步驟：逐條唸出 criterion 與其證據，由使用者當場確認（一句
      話即可，例如「這條符合了嗎？」），非 agent 自行判定通過即勾選；
      使用者不同意時，該條回到「unmet」處理路徑（既有段落已定義）
- [ ] `grep -c "使用者當場\|user confirms\|UAT" skills/keel-finish/SKILL.md`
      確認新文字寫入且未重複
- [ ] 手動走查：對照現有一份已完成的 Success Criteria checklist（如
      `docs/plans/2026-08-07-keel-security-review.md` 的
      Success Criteria），逐條核對新流程文字是否要求「使用者確認」而非
      「agent 自證」
- [ ] 不在此 commit —— 已核實 `~/.claude` 不是 git repo，只是安裝目錄；本 task
      只編輯並用 `diff` 驗證 live 副本，實際 commit 於 Task 7 一次完成（同前次
      `13ee5ee` 慣例：多任務單一 commit，非逐 task commit）

## Task 3: Interfaces block 一致性檢查（Contract Test）  [Risk: Med]

**Delivers:** `keel-exec-reviewer-spec` 審查一個消費前置 task `Interfaces:`
block 的 task 時，新增一條檢查：實際實作的簽章／schema 是否與該 block 所
載一致。若專案存在正式 OpenAPI/AsyncAPI 檔（Task 5 引入的類型），優先讀
該檔並嘗試呼叫既有 contract test 工具（如 `spectral`／`pact` 之輸出）；
工具不存在時，明確回報「未執行 — 無 spectral/pact 可用」並退回純文字比對
（Interfaces block 敘述 vs 程式碼實際簽章），不因此判定 FAIL、也不假裝
執行過。
**Files:** `/Users/wen/.claude/agents/keel-exec-reviewer-spec.md:30-45`（「The
only question you answer」段落，第 4 點「Interface drift」之後）
**Depends on:** none
**Skills:** none
**Interfaces:**
  - Consumes: 既有 `Interfaces:` block 格式（task brief 內既有欄位，
    無需新格式）
  - Produces: 無新輸出格式——沿用既有 `AXIS: spec` / `FINDINGS:` 輸出
    結構，本任務只加一類 finding 的判斷邏輯，不改輸出 schema

- [ ] 在「Interface drift」項目後新增第 5 檢查項：驗證消費的
      `Interfaces:` block 與實作簽章一致，具體流程：(a) 若專案根目錄有
      `*.openapi.yaml`/`*.openapi.json`/`*.asyncapi.yaml` 且已安裝
      `spectral` 或 `pact` CLI（`which spectral`/`which pact` 判斷），
      執行其驗證並引用輸出作為證據；(b) 否則純比對 Interfaces block 文字
      與程式碼簽章，逐字寫出「工具不存在時不得判定 FAIL，只能標註
      confidence 上限與『未執行 contract test 工具，改用文字比對』」
      （比照既有 R3 Global Constraint 之 gitleaks/semgrep 誠實回報模式，
      逐字抄用其「不存在時不擋」的措辭精神）
- [ ] 明確寫出此檢查項與既有第 4 點「Interface drift」的差異：第 4 點是
      「diff 有沒有偏離 Interfaces block 承諾」，本項是「偏離時證據等級
      是文字比對還是工具驗證」——是同一發現的證據強度分級，非新一類
      finding，避免審查者對同一件事回報兩則重複 finding
- [ ] `grep -c "contract test\|spectral\|pact" agents/keel-exec-reviewer-spec.md`
      確認新文字寫入且未重複
- [ ] 手動走查：假想一個 Task B 消費 Task A 的 `Interfaces: Produces:
      login(email: string) -> Session`，但 Task B 實作成
      `login(email: string, remember: bool) -> Session`；核對新檢查項
      文字是否明確要求標註「文字比對發現簽章不符，未執行工具驗證（無
      spectral/pact）」而非直接 FAIL 或直接忽略
- [ ] 不在此 commit —— 已核實 `~/.claude` 不是 git repo，只是安裝目錄；本 task
      只編輯並用 `diff` 驗證 live 副本，實際 commit 於 Task 7 一次完成（同前次
      `13ee5ee` 慣例：多任務單一 commit，非逐 task commit）

## Task 4: keel-plan 功能矩陣產出規則   [Risk: Low]

**Delivers:** `keel-plan` 寫 plan header 時（Step 2），若計畫命中既有
UI/多角色關鍵字判準（沿用 `keel-plan-lens-design` 既有的 2+
view/rendering/UI/component/screen 關鍵字觸發條件，不新造判準），強制
產出一張 feature × state/role/platform 矩陣，存於 plan file 的新增
`## Feature Matrix` 小節（若專案有 `CONTEXT.md` 則額外附一份摘要於該檔，
沿用既有「CONTEXT.md 存在則同步」慣例）。目的：把漏 case 從 review 階段
事後抓（`keel-plan-lens-design`）提前到規劃階段寫的當下。
**Files:** `/Users/wen/.claude/skills/keel-plan/SKILL.md:85-87`（Step 2
「Write the plan header」段落結尾之後、Step 3「Write tasks」開頭之前——
Eng lens 核對後修正，原計畫誤標 114-118（該處實為 Step 3「Rules that
make plans executable」條列內部，非 Step 2/3 交界）
**Depends on:** none
**Skills:** none
**Interfaces:**
  - Consumes: `keel-plan-lens-design.md` 現有的觸發關鍵字清單（讀取比照，
    不重新定義；若該 agent 檔案的關鍵字清單未來變動，此規則自動沿用同一
    來源，不在 keel-plan 內重複硬寫關鍵字列表——用一句話引用該 agent 檔案
    路徑，而非複製關鍵字字面值）
  - Produces: `## Feature Matrix` 小節格式，供 `keel-plan-lens-design`
    Step 3 審查時作為既有「狀態矩陣」輸出的比對基準（該 agent 既有輸出
    已有「狀態矩陣」欄位，本任務讓其有規劃期產出物可比對，而非審查時
    憑空重新枚舉）
- [ ] 在 `keel-plan/SKILL.md` Step 2 之後新增 Step 2b「功能矩陣（條件式）」
      小節：命中判準時（明確寫「與 `keel-plan-lens-design.md` frontmatter
      所載觸發詞彙同一套，不重複定義」），寫一張 markdown 表格，列＝
      功能/畫面，欄＝{empty, error, loading, boundary, role/platform 變體}，
      每格填「已規劃」或具體行為，未規劃格留空以便 review 階段抓漏
- [ ] 明確寫出：未命中判準的計畫完全略過此步驟，不加重非 UI 專案的規劃
      負擔
- [ ] `grep -c "^## Feature Matrix\|Step 2b" skills/keel-plan/SKILL.md`
      確認新文字寫入且未重複
- [ ] 手動走查：假想一個含「登入頁面」「儀表板 UI」的計畫（命中 2+ UI
      關鍵字），核對新規則文字是否要求產出矩陣；再走查一個「CLI 腳本」
      計畫（不命中），核對是否明確略過
- [ ] 不在此 commit —— 已核實 `~/.claude` 不是 git repo，只是安裝目錄；本 task
      只編輯並用 `diff` 驗證 live 副本，實際 commit 於 Task 7 一次完成（同前次
      `13ee5ee` 慣例：多任務單一 commit，非逐 task commit）

## Task 5: PROJECT-TYPE-GUIDE.md — Contract-first 與 Release Runbook 細節   [Risk: Low]

**Delivers:** `PROJECT-TYPE-GUIDE.md` 的「Backend API / database service」
型別新增 contract-first 細節：計畫涉及對外或服務間 API 時，keel-plan 階段
先產出 OpenAPI（同步）或 AsyncAPI（事件/訊息）檔案作為獨立 Task 0 交付物，
凍結後續 task 的 `Interfaces:` block 直接引用該檔而非重複定義簽章。
同時「Finish focus」欄新增部署相關型別（沿用既有 Serverless/edge 型的
「Deploy to preview」精神，擴充為明確的 Release Runbook 產出：部署前置
檢查、部署指令、部署後驗證命令、rollback 指令）。僅套用於命中該型別的
計畫，其餘型別完全不受影響。
**Files:** `/Users/wen/myProject/keel/PROJECT-TYPE-GUIDE.md`
（Quick matrix 表格第 17 行 Backend API row；「### Backend API / database
service」段落第 39-46 行；「### Serverless / edge」段落第 59-64 行）
**Depends on:** none
**Skills:** none
**Interfaces:**
  - Consumes: 無
  - Produces: 「API-heavy」判準措辭與「有正式部署環節」判準措辭，供
    Task 3 的 contract test 工具偵測邏輯與 Task 6 的 README 同步引用

- [ ] 在「### Backend API / database service」段落，「Plan must risk-grade
      every migration task High」之前插入一句：計畫涉及對外或服務間 API
      時，keel-plan 先產出 OpenAPI/AsyncAPI 檔作為獨立 Task 0，後續
      `Interfaces:` block 引用該檔路徑而非重複寫簽章
- [ ] 在「### Serverless / edge」段落現有「Finish requires a preview
      deploy + a real HTTP hit」之後，新增一句：有正式部署環節的專案
      （非 preview-only），keel-finish Part 3 追加產出 Release Runbook——
      部署前置檢查／部署指令／部署後驗證命令／rollback 指令，寫入 PR
      body 或獨立文件；preview-only 部署（如本節既有的 Cloudflare
      preview）不需要，因為 preview 本身可拋棄、無需 rollback 程序
- [ ] `grep -c "OpenAPI\|AsyncAPI\|Release Runbook" PROJECT-TYPE-GUIDE.md`
      確認兩處新文字都寫入且未重複
- [ ] 手動走查：假想一個「新增訂單服務對外 REST API」計畫，核對 Backend
      API 段落新文字是否要求先出 OpenAPI 檔；假想一個「正式環境資料庫
      遷移＋部署」計畫，核對是否要求 Release Runbook
- [ ] Commit（`docs: add contract-first + Release Runbook details to
      PROJECT-TYPE-GUIDE.md`，本 repo `keel`——此檔本身即
      repo 內檔案，非 live-copy，不需 Task 7 補同步）

## Task 6: SDD 三項機制強化（spec 溯源／結構化驗收／核准閘門）   [Risk: Med]

**Delivers:** keel-plan 現有 spec-first 精神補上 SDD 的三個具體機制：
(a) spec 為單一真相源——spec header 新增顯式 `Status: draft|approved` 欄位，
`keel-plan` 的 INPUT contract 檢查此欄位為 `approved` 才可進入，非
approved 時 `BLOCKED: spec 未核准 → 退回 keel-discover`（複用既有
`BLOCKED:` 格式，非新造一套錯誤格式）；spec 核准後若又被修改，`keel-plan`
header 記錄核准時的 spec 版本（commit hash 或修改時間戳），`keel-execute`
既有的「plan 與 code 矛盾則退回 keel-plan」路徑旁新增一條「spec 本體在
執行期間被改到與 plan 記錄的版本不符 → 同樣退回 keel-plan 重新對齊」，
複用 `keel-workflow` 既有 Backward routes 表格的既有列格式，不新造一張表；
(b) Success Criteria 改用結構化驗收格式——`keel-discover` 的 spec 模板與
`keel-plan` 的 plan header 模板，Success Criteria 欄位改寫成 Given-When-Then
三段式（場景／條件／預期結果），取代現行自由 prose checklist，讓每條標準
可直接對應成一個可驗證的斷言而非一句話宣稱。
**Files:** `/Users/wen/.claude/skills/keel-discover/SKILL.md:159-166`
（Write spec 段落，spec 檔案模板處）、
`/Users/wen/.claude/skills/keel-plan/SKILL.md:19-32, 69-85`（INPUT block
與「When to skip」段落於 19-32，Step 2 plan header 模板於 69-85——Eng
lens 核對後修正，原計畫誤標 1-30 未涵蓋實際編輯目標，避開 Task 4 新增的
Step 2b 區塊，改在 header 模板本身動刀，段落不重疊）、
`/Users/wen/.claude/skills/keel-workflow/SKILL.md:30-38`（Backward routes
表格，新增一列）
**Depends on:** Task 4（同時編輯 `keel-plan/SKILL.md`，序列化避免平行編輯
衝突——Task 4 動 Step 2 之後新插入的 Step 2b，本 task 動 INPUT block 與
既有 Step 2 header 模板本身，兩者標的行號不同但同檔案，仍照既有紅旗規則
「不對重疊檔案派平行 implementer」序列化）
**Skills:** none
**Interfaces:**
  - Consumes: 無
  - Produces: `Status: draft|approved` 欄位格式、Given-When-Then Success
    Criteria 格式，供 Task 7 的 README 同步引用；也供未來任何讀 spec/plan
    header 的機制（現有無下游消費者，屬新增介面）

- [ ] 在 `keel-discover/SKILL.md` 的 spec 檔案模板，header 加一行
      `**Status:** draft`；「Then user reviews written spec. Wait explicit
      approval.」那句之後新增：使用者核准後，把該行改為
      `**Status:** approved`，並記錄核准當下的 commit hash 或時間戳於同一
      行（例如 `**Status:** approved (2026-08-07, a1b2c3d)`）
- [ ] 在 `keel-discover/SKILL.md` 的 spec 模板，Success Criteria 欄位改寫
      範例格式為 Given-When-Then 三段式，附一個具體範例（例如：「Given
      使用者已登入, When 點擊登出, Then session 被清除且導向首頁」），取代
      現行純 prose checklist 範例
- [ ] 在 `keel-plan/SKILL.md` 的 INPUT block（檔案開頭 `INPUT` 那行）補一句：
      **若 INPUT 走 spec 路徑**，該 spec 的 `Status:` 欄位須為 `approved`，
      否則 `BLOCKED: spec 未核准 → 退回 keel-discover`（消歧義措辭，避免被
      誤讀成連「requirements clear enough to name exact file paths」與
      Medium shortcut 等無 spec 檔路徑也一併卡住——Eng skeptic 核對後判定
      原措辭雖已隱含此前提但值得明寫，非放行條件變更）；Step 2 的 plan
      header 模板 `**Success
      Criteria:**` 欄位加註：格式沿用 spec 的 Given-When-Then 三段式，
      非改寫成散文
- [ ] 在 `keel-plan/SKILL.md` Step 2 的 plan header 模板新增一行
      `**Spec Version:** <spec 核准時的 commit hash 或時間戳，抄自 spec
      的 Status 欄位>`
- [ ] 在 `keel-workflow/SKILL.md` 的 Backward routes 表格新增一列（比照
      既有列格式）：`| Spec 本體在執行期間被改到與 plan 記錄的
      Spec Version 不符 | keel-execute | keel-plan |`
- [ ] `grep -c "Status: draft\|approved" skills/keel-discover/SKILL.md
      skills/keel-plan/SKILL.md`、`grep -c "Given-When-Then\|Spec Version"
      skills/keel-plan/SKILL.md` 確認新文字寫入且未重複
- [ ] 手動走查：假想一份 spec 標記 `Status: draft`，核對 keel-plan INPUT
      contract 新文字是否明確要求 BLOCKED 退回；再假想一份已
      `Status: approved` 的 spec，核對是否放行；再假想 plan 執行到一半
      spec 檔案被改動（hash 不符 plan header 記錄的 Spec Version），核對
      Backward routes 新列是否命中
- [ ] 不在此 commit —— 已核實 `~/.claude` 不是 git repo，只是安裝目錄；本 task
      只編輯並用 `diff` 驗證 live 副本（三檔互相依賴，一併驗證），實際
      commit 於 Task 7 一次完成（同前次 `13ee5ee` 慣例：多任務單一
      commit，非逐 task commit）

## Task 7: 雙語 README 同步 ＋ keel-finish Part 3 Release Runbook 接線   [Risk: Low]

**Delivers:** `README.md`／`README.zh-TW.md` 反映 Task 1-6 的七項變更（不
新增 roster 列——本輪皆為既有 skill/agent 的接線強化，非新增 agent）；
`keel-finish` Part 3 的 Push+PR 選項後接上 Task 5 定義的 Release Runbook
產出邏輯（讀取 `PROJECT-TYPE-GUIDE.md` 判準決定是否觸發）；provenance
表格新增本次需求書一列。
**Files:** `/Users/wen/myProject/keel/README.md`（Provenance
表格，約第 288-300 行附近）、`README.zh-TW.md`（對應表格）、
`/Users/wen/.claude/skills/keel-finish/SKILL.md:179-192`（Part 3，選項 2
「Push + PR」之後）
**Depends on:** Task 1, Task 2, Task 3, Task 4, Task 5, Task 6
**Skills:** none
**Interfaces:**
  - Consumes: Task 1-6 全部產出的措辭與判準（逐一核對兩份 README 的敘述
    與實際 skill 檔文字一致，不得改寫成不同措辭）
  - Produces: 無（本 task 是整合終端）

- [ ] `README.md`／`README.zh-TW.md` 找到描述 keel-plan-review Step 5、
      keel-finish Part 2、keel-exec-reviewer-spec、keel-plan、keel-discover、
      keel-workflow、PROJECT-TYPE-GUIDE 的既有段落，逐一補上本輪七項變更的
      一句話摘要（比照既有段落的簡潔程度，不展開成教學文）
- [ ] Provenance 表格新增一列，比照既有格式：
      `| keel-workflow SDD 元素整合需求書 (2026-08-07) | internal doc, not a
      repo | sources: 外部分享的 SDD/Contract-first/ADR 流程比對 |`（兩份
      README 各一列，中文版用中文欄位敘述比照既有中文列的措辭）
- [ ] 在 `keel-finish/SKILL.md` Part 3「Push + PR」選項條目之後新增一句：
      若專案命中 `PROJECT-TYPE-GUIDE.md` 的「有正式部署環節」判準
      （Task 5 訂出的措辭），追加產出 Release Runbook 小節寫入 PR body，
      否則略過
- [ ] `grep -c "Release Runbook" skills/keel-finish/SKILL.md` 確認寫入且
      未重複；`diff` 兩份 README 對應段落確認中英文版描述的七項變更
      一致（非逐字翻譯，但涵蓋範圍相同）
- [ ] 本輪共動 9 個檔案（7 個 skill/agent + 2 份 README），超過
      keel-workflow 自身「>8 files → review」門檻——已正確走本次
      keel-plan-review，此處補一道 Eng lens 建議的交叉檢查：對每個
      Task 1-6 改動的檔案跑 `diff <(cat ~/.claude/skills-or-agents/檔案)
      <(cat 本 repo 對應路徑/檔案)`，確認複製進 repo 的內容與 live 副本
      逐位元組一致，不只靠 `grep -c` 存在性檢查（`grep -c` 只驗證新文字
      存在，不驗證整檔複製無漏字/無誤複製舊版本）
- [ ] 在 `TODOS.md` 新增一筆延後項（What/Why deferred/Effort/Priority
      格式）：Task 1-7 皆無 `[→EVAL]` eval-fixture harness（Eng lens
      Low finding）——本輪 7 個 task 都是 prompt/skill 定義檔的規則新增，
      現行驗證只到「手動走查＋grep」層級，缺一個可重複執行的
      `.keel/eval-fixtures/` 假想計畫測試集；Effort: M；
      Priority: Low（非本輪阻斷項，供未來需要迴歸驗證此類變更時使用）
- [ ] 手動走查：Task 1-6 七項 Success Criteria 逐條對照 README 新增文字，
      確認每一項都在 README 有對應一句話提及，無遺漏
- [ ] 將 Task 1-6 全部改動檔案（`keel-plan-review/SKILL.md`、
      `keel-finish/SKILL.md`、`keel-exec-reviewer-spec.md`、
      `keel-plan/SKILL.md`、`PROJECT-TYPE-GUIDE.md`、`keel-discover/SKILL.md`、
      `keel-workflow/SKILL.md`）複製進本 repo 對應路徑（比照前次 `13ee5ee`
      的「最末 task 統一提交」慣例——Task 1-6 只在 live 安裝副本
      `~/.claude/` 下編輯與驗證，不逐一提交；本 task 一次複製全部進 repo
      並提交，Global Constraint 的「propagate 到 live copy」在各 task
      執行當下已用 `cp`+`diff` 完成，此處是反向同步：repo 缺這些檔案的
      最新版，需補齊）
- [ ] Commit（`docs: sync READMEs and repo copies for keel-workflow SDD
      integration`，本 repo `keel`；已核實 `~/.claude` 不是
      git repo，Task 1-6 全程只編輯並用 `diff` 驗證 live 副本，未逐一
      commit，本 commit 是整個計畫唯一的一次提交，承載 7 個 skill/agent
      檔的 repo 端同步 + 兩份 README，同前次 `13ee5ee` 慣例）

## REVIEW REPORT

Lenses: CEO 7→9, Eng 7→9（Design/Security/DX 因判定為關鍵字誤觸發而跳過，
理由已於派工時向使用者揭露）

Decisions:
- [Mechanical] Task 5 Success Criteria 補記與需求書字面措辭的偏離說明（併入
  既有 Backend API 型而非新增第三型）
- [Mechanical] Task 4 Files 行號修正 114-118 → 85-87（Eng lens 抓到原計畫
  誤標）
- [Mechanical] Task 6 Files 行號修正 1-30 → 19-32, 69-85（Eng lens 抓到原
  計畫未涵蓋實際編輯目標）
- [Mechanical] Task 6 INPUT gate checklist 措辭消歧義（明寫「若 INPUT 走
  spec 路徑」），Eng skeptic 反駁 Regression 疑慮後判定原設計無誤，僅措辭
  補強
- [Mechanical] Task 1 附註 ADR 判準既有措辭分歧（keel-discover 逗號 vs
  keel-finish 加號），標記為既有問題非本輪範圍
- [Mechanical] Task 7 新增 diff 位元組級交叉檢查（CEO lens 指出僅
  `grep -c` 不足以驗證整檔複製正確）
- [Mechanical] Task 7 新增 TODOS.md 延後項——eval-fixture harness（Eng lens
  Low finding，非本輪阻斷項）
- [Mechanical] Task 1-6 全部 Commit 步驟修正——keel-execute 前置檢查發現
  `~/.claude` 並非 git repo（`git -C ~/.claude status` 回報 not a git
  repository），先前「逐任務於 `~/.claude` live-copy repo commit」的措辭
  為誤判；核對 precedent `13ee5ee` 亦確認為單一最終 commit、非逐任務
  commit。已改為「Task 1-6 只編輯並用 diff 驗證 live 副本，實際 commit
  於 Task 7 一次完成」
- [Mechanical] 新增「Provenance ＋ 未驗證項」與「Alternatives considered」
  section，含使用者 Step 0 授權 Task 6 的明確記錄（CEO lens Critical
  「範圍外」finding 之正確處置——非撤回 Task 6，是記錄授權來源）
- [User Challenge, REFUTED] Eng lens Critical：Task 6 INPUT gate 會擋既有
  無 spec 檔路徑（Regression Iron Rule）——`keel-plan-skeptic-critical`
  核對後 REFUTED：計畫文字是「補一句」非「改寫 INPUT」，且 Medium
  shortcut 根本不經過 keel-plan 這個 stage，無法建構具體失效情境
- [User Challenge, REFUTED] CEO lens High：ADR 三處機制衝突——
  `keel-plan-skeptic-critical` 核對後 REFUTED：三處觸發的是不同時間點的
  不同決策（spec 階段 vs plan 審查階段 vs 收尾階段），keel-plan 既有
  「不得重新論戰 ADR」規則與 Task 2 的 skip-note 已三重堵死重複產出
- [User Challenge, REFUTED] CEO lens High：Task 6(a) 核准閘門價值被高估——
  `keel-plan-skeptic-critical` 核對後 REFUTED：既有機制是同一 session 內
  的人工等待動作，不是跨 session 可查核的 artifact 狀態；Spec Version
  釘版與 spec 漂移退回路徑在既有 repo 中零對應物，屬新能力
- [Taste] 執行順序——使用者選擇一次全跑 7 個 task，不拆 Batch A/B

Cross-lens themes:
- Theme: Task 4/6 的 Files 行號標錯 — flagged by [Eng]（獨立發現，CEO 未
  觸及行號細節，故非跨 lens 收斂訊號，僅記錄）
- Theme: Task 6 範圍與既有機制重疊/授權來源 — flagged by [CEO, Eng]（CEO
  從「範圍外」角度、Eng 從「INPUT gate 破壞既有路徑」角度，兩份獨立
  fresh-context lens 分別命中 Task 6 是本次審查風險最集中處，經三次
  skeptic 反駁後結論是原設計站得住，但揭露了計畫措辭需要更明確——已修正）

NO UNRESOLVED DECISIONS
