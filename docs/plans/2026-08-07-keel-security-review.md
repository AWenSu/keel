# Plan: keel 資安審查缺口補齊

> **For agentic workers:** execute with keel-execute.

**Goal:** keel-* pipeline 新增計畫期威脅建模 lens 與執行期資安審查軸，使 pipeline
從「只能驗證已存在的資安 finding」升級為「能主動產生資安 finding」，並在
keel-finish 加上資安退場閘門。

**Spec:** `/Users/wen/myProject/Claude/20260807_0009_keel-security-review-requirements-資安審查缺口需求書.md`
（定案版，已補 STRIDE 方法論、OWASP Top 10:2025 A02/A10、套件存在性驗證三處）

**Architecture:**
```
keel-plan          keel-plan-review              keel-execute                    keel-finish
  (標記已有)   →   + keel-plan-lens-security  →  + keel-exec-reviewer-security → + 資安退場閘門
                    (STRIDE 設計期威脅建模)      (R4 條件觸發，第三審查軸)      (R6 新鮮證據)
```
新增兩個 agent（`keel-plan-lens-security`、`keel-exec-reviewer-security`），
其餘為既有五份 SKILL.md／README／CLAUDE.md 的接線變更。無新增外部服務、
無新增資料庫、無 runtime 程式碼變更 —— 全部是 prompt/skill 定義檔。

**Global Constraints（逐字抄自 spec，勿改寫）：**
- 新 agent 輸出格式須與既有 lens／reviewer 一致（score 0-10 或
  AXIS/VERDICT/最重要/信心，依所屬階段）
- 遵循既有 evidence gate（file:line + 引文；外部證據 URL + 取用日期 + 引文）
- 遵循既有 prompt defense baseline
- `keel-plan-lens-security` 明確不做程式碼層級審查（該職責屬
  `keel-exec-reviewer-security`）
- `keel-exec-reviewer-security` **獨立成軸，不併入 quality reviewer**
  （兩軸不得合併排名的既有設計哲學）
- `keel-exec-reviewer-security` **read-only**，finding 由 fixer 修正
- R4 觸發條件（任一命中）：`Files:` 觸及認證/授權/session/加密/上傳/外部呼叫/
  資料庫查詢建構路徑；diff 新增或修改對外端點；task 被 keel-plan 標記高風險；
  計畫階段 security lens 對該 task 留有 finding；diff 命中敏感字串樣式
  （`password`/`secret`/`token`/`api[_-]?key`/`BEGIN.*PRIVATE KEY`/連線字串樣式）
- `keel-exec-reviewer-security` 建議釘 **opus**（不同於 spec/quality 的 sonnet）
- 保留 `~/.claude/agents/security-auditor.md` 不動；只移除
  `keel-plan-review/SKILL.md` 中對它的散文提及
- 不實作掃描工具本身；不做滲透測試自動化；不改 `code-reviewer`；不改
  `keel-debug`；不引入外部資安服務或付費 API

**Success Criteria（抄自 spec §六）：**
- [ ] 含登入與檔案上傳的測試計畫跑 `keel-plan-review`，security lens 自動啟用
      且產出至少一則帶 file:line 證據的 finding，分數列入 REVIEW REPORT
- [ ] 硬寫 API Key 的測試 task 跑 `keel-execute`，security 軸回傳
      `VERDICT: FAIL` 並指出該行
- [ ] 純 CSS 調整的測試 task，security 軸不觸發，ledger 記錄跳過理由
- [ ] 存在未關閉 Critical 資安 finding 時，`keel-finish` 回傳 BLOCKED
- [ ] `keel-plan-review/SKILL.md` 對 `security-auditor` 的散文提及已移除，
      無兩套機制並存
- [ ] 既有 spec 軸與 quality 軸的行為與輸出格式完全未變

## 專案類型調整（非標準 TDD）

本專案是 skill/agent 定義檔（純 markdown prompt），無編譯、無 runtime、無
既有測試框架 —— keel-plan 模板的「write failing test / run / implement /
run / commit」五步驟字面上不適用。spec 也沒有「Test seams」章節（威脅建模
lens 的產物是審查判斷，不是可斷言的程式行為）。

**採用的驗證取代方案**（對齊本 repo 前次同類變更的既有作法 —— 見
`fb5ad03`/`dc11ec6`/`da1c82a` 三次 commit 皆用此法）：每個 task 的驗證步驟
改為 (a) `grep -c` 確認新增內容確實寫入且未重複、(b) 對照 spec 的驗收標準
逐條手動走一遍 dispatch 邏輯（例如：拿一個含 `login`/`upload` 關鍵字的假想
計畫，手動核對 security lens 的觸發規則是否命中）。這不是跳過驗證，是把
「測試」換成這個專案類型真正的求證方式。

## Task 1: 新增 keel-plan-lens-security agent

**Delivers:** 存在一個 `keel-plan-lens-security` agent，職責為設計期 STRIDE
威脅建模。給它一份含使用者登入功能的計畫文字，它回傳的 findings 至少一則
帶 file:line 引文且對應 A01（IDOR/授權前身）或敏感資料流類別；給它一份純
CSS 調整計畫，它應回報「無跨信任邊界元件」而非硬套一個 finding。
**Files:** `/Users/wen/.claude/agents/keel-plan-lens-security.md`（新檔，
比照 `keel-plan-lens-eng.md`、`keel-plan-lens-dx.md` 的 frontmatter/章節結構）
**Depends on:** none
**Skills:** none
**Interfaces:**
  - Consumes: 無（讀 plan file + spec，同其他 lens）
  - Produces: `SCORE:`/`FINDINGS:`/`APPENDIX:`/`CHECKED:` 輸出格式，供
    Task 2 的 keel-plan-review 派工邏輯與 Step 5 決策分類消費

- [ ] 撰寫 agent frontmatter：`name: keel-plan-lens-security`、description
      比照既有 lens 的「【計畫審查／OO 視角】」中文一行摘要格式、
      `tools: Read, Grep, Glob, Bash`（唯讀，不給檢索工具 —— 威脅建模是對
      計畫文字本身的結構化推理，不是找外部先驗，跟 CEO lens 的
      prior-art 掃描性質不同）、`model: opus`（理由：資安漏判的不對稱
      成本，同 skeptic tier routing 既有邏輯；且此 lens 無檢索工具可用
      sonnet 省成本抵銷，opus 換取更完整的 STRIDE 推理鏈）
- [ ] 撰寫 Prompt Defense Baseline 段落（逐字比照既有 lens 的五條）
- [ ] 撰寫「方法論」段落：STRIDE 六類 + 逐一列出計畫新增/修改元件與資料流
      + 每個跨信任邊界處套用六類（抄自需求書 R1 定案文字，不重寫）
- [ ] 撰寫具體檢查項清單八項（信任邊界／認證授權／敏感資料流／不可逆操作
      ／攻擊面／相依風險／設定安全 A02／失敗行為 A10，逐項對應需求書 R1）
- [ ] 撰寫 Evidence gate 段落（比照 `keel-plan-lens-eng.md` 逐字）
- [ ] 撰寫 Output 格式區塊：`SCORE:`/`FINDINGS:`（含證據/信心/建議編輯）/
      `APPENDIX:`/`CHECKED:`，比照既有 lens
- [ ] 明確寫一句「不做程式碼層級審查，該職責屬 keel-exec-reviewer-security」
- [ ] Output 格式的 `FINDINGS:` 段落要求：每則 finding 的建議編輯須標註
      對應的 `## Task N`（若橫跨多個 task 或屬計畫層級，標
      `plan-global`）——這是 Task 4 R4 第四條觸發條件（計畫階段 security
      lens 對該 task 留有 finding）唯一的可查核資料位置，沒有這欄
      keel-execute 端無從判斷某個 task 是否曾被此 lens 標記過
      （keel-plan-review 審查通過的 REVIEW REPORT 是聚合層級摘要，
      無 per-task 結構）
- [ ] `grep -c "STRIDE"` 與 `grep -c "^model: opus"` 確認寫入且各恰好一次
- [ ] Commit（`feat: add keel-plan-lens-security agent — STRIDE threat modeling lens`）

## Task 2: 將 security lens 接入 keel-plan-review

**Delivers:** 對一份命中 2+ 資安詞彙（或高風險標記，或新增對外端點）的計畫
跑 `keel-plan-review`，security lens 被自動選中、順序在 Eng 之後 DX 之前、
跳過時會在 roster 公告中說明理由、分數會出現在最終 REVIEW REPORT。
`security-auditor` 的散文提及已從檔案中完全移除。
**Files:** `/Users/wen/.claude/skills/keel-plan-review/SKILL.md`
（Step 1 第 42-45 行、Step 2 dispatch table 第 57-67 行、Step 2 lens
briefs 段落）
**Depends on:** Task 1
**Skills:** none
**Interfaces:**
  - Consumes: Task 1 的 `keel-plan-lens-security` agent 名稱與輸出格式
  - Produces: 更新後的 lens dispatch table，供 Task 6（keel-workflow roster
    同步）與 Task 7（README 同步）引用

- [ ] Step 1 觸發規則新增第三條件式 lens：資安詞彙命中
      （auth/login/session/token/secret/key/credential/permission/role/
      upload/個資/PII/payment/delete/export/webhook/external API 任 2+
      命中）**或** 計畫 Global Constraints/任一 task 帶高風險標記 **或**
      新增任何對外可達端點（三者任一觸發即啟用，抄自需求書 R2 逐字）
- [ ] Step 2 dispatch table 新增一列：
      `| Security | keel-plan-lens-security | 資安詞彙 2+／高風險標記／新增對外端點 |`，
      置於 Eng 之後、DX 之前
- [ ] Step 2「Run lenses — sequential」段落的執行順序敘述改為
      `CEO → Design → Eng → Security → DX`
- [ ] 新增 Security lens 的 lens brief（比照既有 CEO/Eng/Design/DX brief
      的段落格式，內容：只需一句指向 Task 1 agent 的方法論，不重複全文）
- [ ] 刪除第 64-67 行「Optional specialist lenses...`security-auditor`
      (auth, secrets, user data, irreversible operations)...」整段散文
      —— 保留 `test-engineer`、`silent-failure-hunter` 兩個仍缺對應具名
      agent 的項目，只移除 `security-auditor` 那一項
- [ ] Announce roster 段落：確認「跳過時須說明理由」的既有規則自然涵蓋
      新的條件式 lens，不需重寫（Design/DX 已是同構）
- [ ] provenance frontmatter 補一行：本次變更來源指向需求書
      （`20260807 資安審查缺口需求書 R1/R2/R7`）
- [ ] `grep -c "security-auditor"` 確認結果為 0（散文提及完全移除）；
      `grep -n "keel-plan-lens-security"` 確認 dispatch table 與 brief
      兩處都有
- [ ] Commit（`feat: wire keel-plan-lens-security into keel-plan-review Step 1/2`）

## Task 3: 新增 keel-exec-reviewer-security agent

**Delivers:** 存在一個 `keel-exec-reviewer-security` agent，read-only，給它
一段含硬寫 API Key 的 diff，回傳 `VERDICT: FAIL` 並指出該行；給它一段純
CSS 調整 diff（理論上不會被派工，但邏輯本身要能正確判斷），回傳
`VERDICT: PASS` 或空 finding。
**Files:** `/Users/wen/.claude/agents/keel-exec-reviewer-security.md`
（新檔，比照 `keel-exec-reviewer-quality.md`、`keel-exec-reviewer-spec.md`
的 frontmatter/章節結構）
**Depends on:** none
**Skills:** none
**Interfaces:**
  - Consumes: 無（讀 diff + task brief，同其他 reviewer）
  - Produces: `AXIS: security` 輸出格式，供 Task 4 的 keel-execute 第三軸
    接線與 fix loop 消費

- [ ] 撰寫 agent frontmatter：`name: keel-exec-reviewer-security`、description
      比照「【執行／資安軸審查】」格式、`tools: Read, Grep, Glob, Bash`
      （唯讀，同 spec/quality 兩軸）、`model: opus`（需求書 R5：漏判成本
      不對稱，同 skeptic 既有邏輯；R4 觸發條件已限制呼叫量，成本可承受）
- [ ] 撰寫 Prompt Defense Baseline（逐字比照 `keel-exec-reviewer-quality.md`）
- [ ] 撰寫「Diff base」段落（逐字比照兩個既有 reviewer：base commit 明確
      給出、never `HEAD~1`、無 base 則 BLOCKED、排除 `.keel/`）
- [ ] 撰寫最低檢查清單十項（Secrets／AuthN-AuthZ（含 session 管理：cookie
      屬性、逾時、固定攻擊防範）／注入／輸入驗證／輸出編碼／SSRF與
      反序列化／加密／錯誤與日誌洩漏／相依套件（含套件存在性驗證，防
      slopsquatting）／檔案上傳，逐項對應需求書 R3 定案文字）
- [ ] 撰寫「你不判斷什麼」段落：不判斷是否符合 task 的 Delivers（spec 軸
      職責）、不判斷程式碼風格/可維護性（quality 軸職責）——兩軸不得合併
      排名的既有規則同樣適用於三軸
- [ ] 撰寫 Evidence gate 段落（逐字比照既有兩軸）
- [ ] 撰寫 Plan-mandated findings 段落：與 spec/quality 兩軸相同，衝突
      計畫原文的 finding 標 `PLAN-CONFLICT`，永不自行修、永不靜默丟棄
- [ ] 撰寫 CodeGraph 查核段落（逐字比照既有兩軸，英文查詢）
- [ ] 撰寫 Output 格式：`AXIS: security` / `VERDICT` / `最重要` /
      `FINDINGS`（含證據/異味或漏洞類別/信心/建議）/ `APPENDIX` / `CHECKED`
- [ ] `grep -c "AXIS: security"` 與 `grep -c "^model: opus"` 各確認恰好一次
- [ ] Commit（`feat: add keel-exec-reviewer-security agent — third review axis`）

## Task 4: 將 security 軸接入 keel-execute 第三審查軸

**Delivers:** `keel-execute` 每個 task 的「Review the diff with two
independent reviewers」步驟，在 R4 五條觸發條件任一命中時，額外派出
`keel-exec-reviewer-security` 為第三軸；不觸發時 ledger 明確記錄
`security axis skipped — <理由>`；三軸輸出彼此不得合併排名；model
matrix 新增一列釘 opus；provenance 記錄本次來源。
**Files:** `/Users/wen/.claude/skills/keel-execute/SKILL.md`（Step 3 第
103-133 行、Model selection table 第 182-196 行、provenance frontmatter）
**Depends on:** Task 3
**Skills:** none
**Interfaces:**
  - Consumes: Task 3 的 `keel-exec-reviewer-security` agent 名稱、輸出格式、
    model 釘選
  - Produces: 更新後的 per-task 審查步驟與 model matrix，供 Task 6
    （keel-workflow roster）與 Task 7（README）引用

- [ ] Step 3 標題「Review the diff with two independent reviewers」改為
      「Review the diff — spec/quality always, security when triggered」
- [ ] Step 3 新增 (c) `keel-exec-reviewer-security` 段落：R4 五條觸發條件
      逐字列出（`Files:` 觸及認證/授權/session/加密/上傳/外部呼叫/DB查詢
      建構路徑；diff 新增或修改對外端點；task 被 keel-plan 標高風險；計畫
      階段 security lens 對該 task 留有 finding；diff 命中敏感字串樣式）；
      任一命中才派工，不觸發時 ledger 記錄 `security axis skipped — <理由>`
      （沉默跳過視為缺陷，同 fan-out ceiling 的既有精神）
- [ ] 觸發時的 ledger 條目格式沿用 `.keel/progress.md` 既有的
      spec/quality 兩軸格式（agent 名稱／VERDICT／finding 數與最高
      severity），第三軸只是多一列，不另訂新格式；未觸發時才用上面的
      `security axis skipped — <理由>` 精簡行
- [ ] 第一條件（`Files:` 觸及...路徑）判定方式明訂為語意判斷，不是純
      檔名關鍵字比對：依 keel-plan 既有規則「Delivers 是真相、Files 是
      提示」，此處同樣以該 task 的 `Delivers:` 敘述內容判斷是否觸及認證
      /授權/資料存取邏輯（例如 diff 修改既有資料查詢的擁有者過濾條件，
      即使 `Files:` 只寫 `services/order.py` 沒有 auth 字樣，仍算觸發）
- [ ] 第四條件（計畫階段 security lens 對該 task 留有 finding）判定方式
      明訂：對照 Task 1 產出的 `FINDINGS:` 中每則的 `## Task N` 標註，
      若標註等於目前 task 編號即成立；標 `plan-global` 者不歸屬任一
      task，於 Step 3 開頭统一提示一次，不重複觸發個別 task。此條件的
      語意是「計畫階段曾針對此 task 提出過的 finding」，不是「仍未
      關閉」——`keel-plan-review` 的 exit gate 要求 `NO UNRESOLVED
      DECISIONS` 才能進入 keel-execute，若照「未關閉」字面理解，此條件
      在進入 keel-execute 時必然恆為假
- [ ] 新增第六條件：diff 新增相依套件清單中原本不存在的套件名稱（新增
      條目，非版本升級）。但這條不是為了防漏判——純套件清單變更（無
      auth/upload/敏感字串 命中）交由 keel-finish Part 2c(3) 把關即可，
      不需要在此再開一次 opus 呼叫；此條件存在只是讓 ledger 的
      `security axis skipped` 理由能明確指名「歸屬 Part 2c(3)」，避免
      讀者誤以為完全沒人管
- [ ] 「Never merge or rerank across the two axes」段落改寫為
      「across axes」（涵蓋二或三軸皆適用），補一句：三軸各自獨立回報，
      重複本身不是問題，合併排名才是（抄自需求書風險表定案措辭）
- [ ] 同段落上方第 115 行「Review the diff with two independent
      reviewers」同步改為「the independent reviewers」（拿掉
      「two」）——這行是舊有二軸措辭殘留，本任務引入第三軸後若不改，
      文件內部會自相矛盾（上面才改完「across the two axes」，緊接著
      又冒出「two independent reviewers」）
- [ ] Fix loop 段落（Step 4）確認 Critical/Important 的 load-bearing 定義
      （第 148 行）已涵蓋 security finding —— 核對現有措辭「breaks a
      Delivers: line, security, data integrity」已包含 security 字樣，
      **若已存在則不重複改寫，只在 self-review 記一句確認**
- [ ] Model selection table 新增一列：
      `| keel-exec-reviewer-security | opus | R4 觸發時的第三審查軸 — 漏判成本不對稱 |`
- [ ] provenance frontmatter 補一行來源（同 Task 2 格式，指向需求書
      R3/R4/R5）
- [ ] `grep -c "keel-exec-reviewer-security"` 確認 Step 3、Model table 兩處
      皆有；`grep -c "security axis skipped"` 確認恰好一次
- [ ] 手動核對驗收標準：純 CSS task（`Files: styles/button.css`）不命中
      任何 R4 條件 → 不觸發，正確；新增登入端點 task
      （`Files: api/auth/login.py`）命中「觸及認證路徑」→ 觸發，正確
- [ ] Commit（`feat: wire keel-exec-reviewer-security as conditional third axis in keel-execute`）

## Task 5: keel-finish 資安退場閘門

**Delivers:** `keel-finish` 的 Part 2（Success criteria check）之後新增
資安檢查小節，存在未關閉的 Critical 資安 finding 時整個 keel-finish
回傳 BLOCKED，不得宣告完成；secrets 掃描工具不存在時明確標示未執行，
不靜默略過。
**Files:** `/Users/wen/.claude/skills/keel-finish/SKILL.md`（Part 2 與
Part 2b 之間插入新小節；provenance frontmatter）
**Depends on:** Task 4
**Skills:** none
**Interfaces:**
  - Consumes: Task 4 的 security 軸 finding 記錄位置
    （`.keel/progress.md` 的 skip/finding 記法）、Task 2 的
    security lens finding（若計畫階段跑過）
  - Produces: 無下游消費者（pipeline 最終階段）

- [ ] 新增「Part 2c: 資安退場檢查」小節，四項檢查（逐字對應需求書 R6）：
      (1) 全分支 secrets 掃描結果（建議 gitleaks 或等效工具；環境無此
      工具 → 明確標示「未執行」，不得靜默略過，比照既有
      CodeGraph-not-indexed 的誠實回報慣例；若已安裝 gitleaks/semgrep，
      此項可從「未執行」升級為工具實際輸出，屬非強制的加分項，不因
      環境無此工具而 BLOCKED——spec §四已明確排除「引入外部資安服務或
      需付費 API」，硬性要求安裝 OSS 掃描器會在本機環境下讓 keel-finish
      每次必然 BLOCKED，屬誤報疲勞，非本案設計目標）
      (2) 執行階段 security 軸的所有 Critical/Important finding 均已關閉，
      或有使用者明示的接受風險決策
      (3) 新增相依套件檢查，拆兩部分：(3a) 已知 CVE／維護狀態掃描，同
      (1) 的工具存在性規則；(3b) 套件存在性驗證（防 slopsquatting，即
      Task 3 checklist 已定義的項目）——這是純 LLM + registry 查詢，不
      依賴外部掃描工具，**沒有「未執行」豁免**，必須實際執行
      (4) 若計畫階段跑過 security lens，其 Critical finding 的落實狀態
- [ ] 明訂 BLOCKED 條件：存在未關閉 Critical 資安 finding 且無使用者
      接受風險決策 → keel-finish 回傳 `BLOCKED: 資安 finding 未關閉`，
      不得進入 Part 3（分支整合）。此條件涵蓋 (2)(3b)(4) 產生的 Critical
      finding；(1)(3a) 因允許誠實回報「未執行」而不強制 BLOCKED——
      「未執行」本身是明示狀態，不是靜默略過，區分於「假裝檢查過」
- [ ] Part 2c 產生的「使用者接受風險」決策，寫入格式沿用既有
      `keel-plan-review` 的 `TODOS.md` 條目慣例（What / Why deferred /
      Effort / Priority，此處額外加 finding 的 file:line），不新開一套
      `.keel/progress.md` 格式——decider 在此單人互動式 pipeline
      中恆為當下使用者，時間可從 commit/TODOS.md 條目本身回推，不需要
      額外的「決策者」「時間」欄位增加儀式性負擔
- [ ] 這四項納入既有 Part 1 Gate Function 的「claim → 需證據」表格精神：
      每項檢查都要有「這次 session 產出的新鮮證據」，不可用舊掃描結果
      （比照 IRON LAW）
- [ ] Part 3（分支整合）既有的 `code-reviewer` 派工提示詞，補一句告知
      「哪些 task 已跑過 security 軸」（從 Task 4 的 ledger 記錄取得），
      讓它把力氣放在跨 task 組合風險，不重掃單一 task 已查過的項目——
      **只改 `keel-finish/SKILL.md` 裡呼叫 `code-reviewer` 時給的 context，
      不改 `~/.claude/agents/code-reviewer.md` 本身**，不牴觸本計畫
      Global Constraints「不改 code-reviewer」的既有排除項
- [ ] provenance frontmatter 補一行來源（指向需求書 R6）
- [ ] `grep -c "Part 2c"` 與 `grep -c "gitleaks"` 各確認恰好一次
- [ ] 手動核對驗收標準：模擬一個「Critical 資安 finding 未關閉」情境，
      走一遍新小節文字，確認邏輯上必然導向 BLOCKED 而非可跳過
- [ ] Commit（`feat: add security exit gate to keel-finish (Part 2c)`）

## Task 6: keel-workflow roster 同步 + security-auditor 舊敘述清理

**Delivers:** `keel-workflow/SKILL.md` 的 subagent roster 表新增兩列
（`keel-plan-lens-security`、`keel-exec-reviewer-security`），與 Task 1/3
的實際 model 釘選一致；同表既有 `security-auditor` 一列的 Stage/Role
欄位更新，不再暗示它涵蓋 stage 3 計畫審查（該職責已移交
`keel-plan-lens-security`）。**不修改 `~/.claude/CLAUDE.md`**——實查該檔
Custom Agents 路由表只收錄使用者手動路由的 9 個 agent，現有 9 個
`keel-*` pipeline 內部 agent（`keel-plan-lens-ceo/eng/design/dx` 等）
一個都不在其中，因為它們是 pipeline 內部派工、使用者從不手動叫。兩個新
agent 屬同一類，比照既有慣例不入全域路由表；roster 記於
`keel-workflow/SKILL.md` 已足夠可查。
**Files:** `/Users/wen/.claude/skills/keel-workflow/SKILL.md`（第 82-101
行 roster 表，含既有 `security-auditor` 列）
**Depends on:** Task 1, Task 3
**Skills:** none
**Interfaces:**
  - Consumes: Task 1/3 的 agent 名稱與 model 釘選（須逐字一致，不得漂）
  - Produces: 無下游消費者（roster 表是給人看的路由參考，不是程式介面）

- [ ] `keel-workflow/SKILL.md` roster 表新增：
      `| keel-plan-lens-security | 3 review | STRIDE 威脅建模（設計期） | opus |`
      置於 `keel-plan-lens-dx` 之後、`keel-plan-skeptic` 之前（依 stage 3
      執行順序排列，同表既有慣例）
- [ ] 同表新增：
      `| keel-exec-reviewer-security | 4 execute | 第三審查軸（R4 條件觸發） | opus |`
      置於 `keel-exec-reviewer-quality` 之後
- [ ] 同表既有 `security-auditor` 一列（第 98 行，現寫
      `| security-auditor | 3/5 | Security-class findings | opus |`）
      改寫 Stage 欄位為僅涵蓋 `/security-review`／`/ship` 這類即興呼叫，
      拿掉暗示涵蓋 stage 3 的部分（例如把 `3/5` 改為 `即興`，並在 Role
      欄位註明「非 keel-plan-review/keel-execute 自動派工」）——這是舊機制
      被新機制取代後留下的殘留敘述，不清理會讓 roster 表本身出現
      「以為有涵蓋」的假象，恰是本案要消除的那類問題
- [ ] `grep -c "keel-plan-lens-security"` 與
      `grep -c "keel-exec-reviewer-security"` 確認各恰好一次
- [ ] Commit（`docs: sync security agents into keel-workflow roster; clarify security-auditor's non-pipeline scope`）

## Task 7: README 雙語同步 + 全案自我複查

**Delivers:** `README.md`／`README.zh-TW.md` 的 provenance 表、roster 表、
gate 說明，反映兩個新 agent 與 keel-finish 新增的資安閘門；spec 軸與
quality 軸的既有段落逐字比對確認未被誤改。
**Files:** `/Users/wen/myProject/keel/README.md`、
`/Users/wen/myProject/keel/README.zh-TW.md`；並將 Task 1-6
在 `~/.claude/agents/` 與 `~/.claude/skills/` 的變更同步複製進本 repo
對應路徑（`agents/keel-plan-lens-security.md`、
`agents/keel-exec-reviewer-security.md`、
`skills/keel-plan-review/SKILL.md`、`skills/keel-execute/SKILL.md`、
`skills/keel-finish/SKILL.md`、`skills/keel-workflow/SKILL.md`）
**Depends on:** Task 1, Task 2, Task 3, Task 4, Task 5, Task 6
**Skills:** none
**Interfaces:**
  - Consumes: 全部前六個 task 的最終檔案內容
  - Produces: 無（案子終點）

- [ ] 兩份 README 的 Subagent roster 表各新增兩列（同 Task 6 的兩列，
      中文版用白話重寫非逐句翻譯，比照本 repo 既有慣例）
- [ ] 兩份 README 的 Provenance 表補一行，指向本次需求書與資料來源
      （STRIDE / OWASP Top 10:2025 / Veracode 2025 GenAI report /
      slopsquatting 研究）
- [ ] 兩份 README 的 gate 說明段落（若有提及審查軸數量的敘述）改「兩軸」
      為「二至三軸（依 R4 條件）」，找不到這類敘述則略過此項不硬加
- [ ] 兩份 README 現存「three general-purpose specialists」（`README.md:204-206`、
      `README.zh-TW.md:150` 附近）點名 `security-auditor` 一句，改寫為
      不再暗示它是 pipeline 內建三軸之一——同 Task 6 對 roster 表的處理，
      這句話與 Stage 欄位是同一個殘留敘述在兩處分別出現，須一併清理，
      否則 README 仍會讓讀者以為 security-auditor 涵蓋 stage 3/4
- [ ] 執行同步：對照 `~/.claude/agents/` 與 `~/.claude/skills/` 的六個
      異動檔，`diff` 確認 repo 對應路徑完全一致，不一致就複製過去
- [ ] 自我複查一輪：`grep -c "reviewer-spec\|reviewer-quality"` 在
      `keel-execute/SKILL.md` 確認出現次數與變更前相同（既有兩軸行為與
      輸出格式完全未變，對應 spec 驗收標準第 6 項）
- [ ] `git status --short` 確認六個 skill/agent 檔 + 兩份 README 皆已加入
      預備 commit 範圍，無遺漏檔案
- [ ] Commit（`docs: sync READMEs and repo copies for keel security review addition`）

## Self-review

- 每條 spec 需求 R1-R8 都對應到至少一個 task：R1→Task1, R2→Task2,
  R3→Task3, R4→Task4, R5→Task3+4, R6→Task5, R7→Task2+7, R8→Task6+7 ✓
- Placeholder 掃描：全文無 TBD／「執行時再定」／「Task N 同上」／未定義
  型別 ✓
- Type-consistency：`keel-plan-lens-security`、`keel-exec-reviewer-security`
  兩個名字在全部 7 個 task 中拼寫一致，未出現變體（如
  `keel-plan-lens-security`）✓
- 每個 phase 結束系統仍可運作：Task 1/3（純新增檔案）完成後既有 pipeline
  行為零變化；Task 2/4 完成後才真正接線，但接線前後既有兩軸/四 lens
  行為不變（僅新增條件式第三者）；Task 5 是純加規則，不影響既有 Part
  1/2/3 ✓
- 觸及檔案數（15 個：2 新 agent + 5 skill + 1 CLAUDE.md-adjacent roster
  表 + 2 README + 6 個 repo 內對應副本 + TODOS.md）超過 keel-plan Exit
  段「>8 files」的送審門檻，本身即是「此計畫須走 keel-plan-review」的
  理由之一，不是需要壓低的異常值——安全機制橫跨計畫/執行/退場三階段、
  兩份文件語系，檔案數是任務本質的直接反映，非拆分不當或範圍蔓延；
  各 task 已用 Depends on 分批，單一 task 的可審查範圍仍小

## Depends on 總覽（供 Step 6 quiz 用）

```
Task 1 (新 lens agent)       — none
Task 2 (接線 keel-plan-review) — Task 1
Task 3 (新 reviewer agent)   — none
Task 4 (接線 keel-execute)     — Task 3
Task 5 (keel-finish 閘門)      — Task 4
Task 6 (keel-workflow roster 同步)— Task 1, Task 3
Task 7 (README + repo 同步)   — Task 1, Task 2, Task 3, Task 4, Task 5, Task 6
```

## REVIEW REPORT

**Lenses:** CEO 6→8, Eng 6→9, security-auditor 6→8

**Decisions（Mechanical，自動套用）：**
- Sec-5：R4 第一條件改語意判斷（依 `Delivers:` 而非純檔名比對）
- Eng-1（UPHELD，經 skeptic 擴大範圍）：R4 第四條件語意釐清——「曾標記」而非「仍未關閉」，並補 Task 1 output 格式的 `## Task N` 標註欄位作為唯一可查核資料位置
- SEC-1（WEAKENED）：secrets 掃描工具缺席時「未執行」誠實回報、不強制 BLOCKED；避免本機環境每次必然 BLOCKED 的誤報疲勞
- SEC-2（WEAKENED）：新增 R4 第六觸發條件（新增相依套件），但僅作 ledger 歸屬標註（指向 keel-finish Part 2c(3)），不另開 opus 呼叫
- SEC-3（WEAKENED，與 SEC-1 同址合併）：keel-finish Part 2c 拆分 (3a)CVE掃描／(3b)套件存在性驗證兩部分，(3b) 無「未執行」豁免、必須實跑；Part 2c 決策改沿用既有 TODOS.md 格式，不新開 persistence 格式
- Eng-2：`keel-execute/SKILL.md:115` 殘留「two independent reviewers」措辭同步改寫
- Eng-3：roster 表 + 兩份 README 的 `security-auditor` 殘留敘述澄清，不再暗示涵蓋 stage 3/4
- Eng-4：Self-review 補一段justification，說明 15 觸及檔案數是安全機制橫跨三階段+雙語文件的直接反映，非拆分不當
- Eng-5：Task 4 觸發時 ledger 條目格式沿用既有 spec/quality 兩軸格式
- Sec-6：Task 3 checklist AuthN/AuthZ 項目補 session 管理（cookie屬性/逾時/固定攻擊防範）
- CEO-5：Task 6 移除 `~/.claude/CLAUDE.md` 修改項——實查該檔路由表不收錄任何內部 `keel-*` pipeline agent，兩個新 agent 比照既有慣例不入表
- CEO-6：Task 5 補一句，keel-finish 呼叫既有 `code-reviewer` 時附上「哪些 task 已跑過 security 軸」context，聚焦跨 task 組合風險；只改 keel-finish 端 context，不改 code-reviewer 本身，不牴觸 Global Constraints

**Decisions（Taste，使用者回答）：**
- CEO-4：STRIDE lens（Task 1/2）與 Task 3-7 同批出貨，不分階段
- Sec-8：security lens 的相依套件檢查只要求點名套件、不給檢索工具驗證，維持計畫原設計
- Eng-6：不補 eval suite，沿用既有 grep+人工走查替代方案

**REFUTED（skeptic 否決，不套用）：**
- CEO-1（SAST 工具缺席論證）、CEO-2（hook 層替代方案）、CEO-3（能力上限敘述）、SEC-4（STRIDE 缺 Repudiation/DoS）

**Appendix-only（信心 ≤5，不強制修改）：**
- Sec-7（CSRF，信心 4）
- Sec-9（R6/Task 3 套件檢查重複，信心 4）

**Cross-lens themes：**
- Theme: gitleaks/相依套件掃描工具存在性與誠實回報邊界 — flagged by [CEO, security-auditor]（CEO-1 雖被 skeptic 駁回，但與 SEC-1/SEC-2/SEC-3 在同一議題上獨立收斂，最終處理方式統一為「工具缺席→誠實標示未執行、不強制 BLOCKED，但套件存在性驗證等純 LLM 檢查無此豁免」）

NO UNRESOLVED DECISIONS
