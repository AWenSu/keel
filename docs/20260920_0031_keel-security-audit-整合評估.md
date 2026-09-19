# keel-security-audit 整合評估

- 評估對象：Cloudflare `security-audit-skill`，commit `c1c8a8c1471069fb0e188eeaff69b8e8db6564a8`，MIT 授權
- 委託來源：review claude 派工（2026-09-19）
- 評估日期：2026-09-20

## 結論

**加，但只加一個「獨立、手動觸發、只讀原始碼」的旁線，叫 `keel-audit`。主流程
（discover → plan → plan-review → execute → finish）的行為與長度完全不動。**

理由一句話：keel 現有三道資安防線都只看「這次改的東西」（計畫、單一 task 的
diff、整個 branch 的 diff），沒有任何一道會去看「沒人在改的舊程式碼」。上游
這套剛好補這一格，而且它最有價值的三樣東西——覆蓋率帳本、不帶嚴重度的
`needs_validation` 狀態、機器可驗證的輸出格式——是本機現有工具都沒有的。

不值得搬的部分（執行目標程式碼、檔案升級程序、外部安裝方式）全部留在上游檔裡
不用，而且在本機本來就不能用（見 a）。

## 四項查證

標記說明：**已驗證** = 本次實際跑過指令或讀過原文；**推測** = 由文件推論、沒有實測。

### a. 「隔離的 loopback」在 macOS 能不能做、怎麼降級

| 上游要求的控制 | 本機（macOS 26.6.2，arm64） | 狀態 |
|---|---|---|
| 完全不能連外網 | `sandbox-exec` 設 `(deny network*)`，沙箱裡 `curl https://example.com` 回 `000` | **已驗證：做得到** |
| 只准用「隔離的」本機迴路 | 開 localhost 例外後，沙箱裡 `curl http://127.0.0.1:9749/` 回 `200`——打到的是使用者本機真正在跑的 codebase-memory 服務。`lsof` 列出本機迴路上掛著十幾個服務（Discord、Figma agent、雲端硬碟同步等）。macOS 沒有網路命名空間，迴路是跟主機共用的 | **已驗證：做不到** |
| 記憶體上限 | `ulimit -v 100000` 回 `setrlimit failed: invalid argument` | **已驗證：做不到** |
| CPU、檔案大小、行程數上限 | `ulimit -t`、`-f`、`-u` 都能設 | **已驗證：做得到** |

**降級方式：只讀原始碼，完全不執行目標程式碼。** 這不是 keel 自己發明的降級——
上游 `SKILL.md` 的「Universal execution safety」段本來就寫明：任何一項控制做不到，
就不准執行目標程式碼，改把那個問題記成 `needs_validation` 並寫明缺哪項控制。
keel 做的只是把它變成結構上的保證：兩個新 agent 只拿到 `Read, Grep, Glob`，沒有
shell，想執行也執行不了。

### b. 實際 token／agent 數成本

**已試跑（2026-09-20，使用者同意）**：對象 keel 自己，`34362e2`，`quick`，預算 16。
**已驗證**的實測數字：

| 項目 | 數字 |
|---|---|
| agent 呼叫 | 14 次（偵察 4、獵捕 5、候選驗證 4、最終覆蓋評審 1），剩 2 |
| 子 agent token | 約 91 萬（偵察約 26 萬、獵捕約 41 萬、驗證約 17 萬、評審約 8 萬） |
| 時間 | run-metadata 建立到 findings.json 寫出約 12 分鐘（00:37 → 00:49） |
| 覆蓋單元 | 10 個：covered 3、candidate 4、deferred 3 |
| 結果 | 候選 4 個（其中 2 個獵捕者提為 `confirmed`），獨立驗證後 **4 個全部 rejected**；成立 0、待驗證 0 |
| 驗證腳本 | `validate-findings.cjs` 4 筆通過、`validate-coverage-ledger.cjs` 10 單元通過 |

輸出在 `~/security-audit-skill/keel/run-1/`（不在 repo 內）。

試跑暴露的 keel 端問題，已修進 `agents/keel-audit-hunter.md`：
1. 4 個候選的駁回理由都是「沒有越過信任邊界」（行動者是使用者、維護者或權限不低於受害方的 agent）。
   獵捕者沒先講清楚誰是低信任方就提候選 → 加一條「提候選前先指名低信任方與他多拿到什麼」。
2. 3 個單元的 `reviewed_paths` 列了沒有任何檢查擁有的路徑，帳本驗證腳本報錯，由 parent 手動剔除
   → 加一條「列出的路徑必須有檢查擁有」。

以下保留試跑前的文件層推算，供對照：

文件層推算（**推測**，依上游 `SKILL.md`「Cost budget」段）：

- 預算單位是「agent 呼叫次數」，不是 token。
- `quick` 的最低保留：偵察 4 次 + 覆蓋評審 1 次 + 驗證者至少 1 次，再加上每個覆蓋
  單元約 1 次獵捕、每個存活候選 1 次驗證。小型 repo 估計落在十幾到二十次呼叫。
- `standard` 每一波獵捕前要保留 2 次評審；`deep` 每個候選要 2 個獨立驗證者。
- keel 的預設給 `quick` + 預算 16 次呼叫；預算不夠支撐最低保留時，照上游規則直接
  記成「未完成」、不啟動任何 agent。

**已驗證**的部分只有：上游兩支驗證腳本只用 node 內建模組、零外部套件；在 keel 內的
複本上跑它們自帶的測試，65 項全過。

### c. 與既有能力的重疊（都讀了實際內容）

| 工具 | 範圍 | 有沒有獨立驗證者 | 有沒有覆蓋率帳本 | 狀態 |
|---|---|---|---|---|
| `~/.claude/agents/security-auditor.md`（5.9KB） | 單一 agent，照 6 類清單走一遍；沒釘死模型與工具 | 沒有 | 沒有 | **已驗證** |
| gstack `/cso`（74KB + 14KB 章節檔） | **已經是整庫稽核**：基礎設施、秘密歷史、供應鏈、CI、skill 供應鏈、OWASP、STRIDE；有 `--diff`、`--scope` | 有（每個發現派一個全新子任務打分，第 1037 行） | 沒有 | **已驗證** |
| 內建 `security-review` | 系統清單只有名稱、沒有說明，也不在磁碟上 | — | — | **推測**：Claude Code 內建版本審的是當前 branch 的待合併改動，屬 diff 範圍；未能讀到原文 |

結論：「整庫稽核」這件事本機其實已經有 `/cso` 做了，所以 keel-audit 不是補
「本機沒有整庫稽核」，而是補 `/cso` 沒有的三樣東西：

1. **覆蓋率帳本** + 驗證腳本——明確記錄哪些部分看過、哪些沒看，並且由程式檢查
   這份宣稱是否自洽。`/cso` 用信心門檻（8/10）過濾，低於門檻的直接不報，看不出
   「沒報」是「沒問題」還是「沒看」。
2. **`needs_validation`**——決定性事實在原始碼之外時（部署、代理、雲端設定），記成
   「被擋住的假設」，而且**不給嚴重度**，不會被誤讀成低危漏洞。
3. **每個候選必須講出「越過了哪個信任邊界、影響到誰」**，講不出來就不算發現。

這三點跟 keel 一貫的紀律（證據閘門、「說出缺席比沉默誠實」、不准空跑也回報通過）
完全同方向，所以適合放進 keel，而不是另外裝一套。

### d. 20260807 資安審查缺口需求書

找到：`~/myProject/Claude/20260807_0009_keel-security-review-requirements-資安審查缺口需求書.md`
（**已驗證**）。

- R1–R8 全部是「以 diff 或階段為範圍」的需求：R1/R2 計畫階段資安 lens、R3/R4/R5
  執行階段資安軸、R6 finish 退場閘門、R7 與 `security-auditor` 的關係、R8 文件。
- 缺口總表逐階段列出，**沒有一項是整庫稽核**。
- 範圍界線明寫：「不做滲透測試自動化——動態測試需要執行環境，超出 pipeline 職責」。

所以這次整合**不對應**需求書任何一項，也不與既有實作重疊；而且因為只讀原始碼、
不執行，也沒有違反需求書的範圍界線。R7「保留 `security-auditor` 不動」照舊遵守。

## 實際做了什麼

### 新增檔案

| 檔案 | 大小 | 作用 |
|---|---|---|
| `skills/keel-audit/SKILL.md` | 7.3KB | 入口檔：只寫 keel 的適配層（角色對應、只讀原始碼、絕對路徑、預算），方法一律按需指向上游 |
| `skills/keel-audit/upstream/`（22 檔） | 356KB | 上游原樣收錄，含 `LICENSE`、`UPSTREAM_SHA.txt`；只有執行時才被讀取，不佔平常的上下文 |
| `agents/keel-audit-hunter.md` | 2.3KB | 偵察、獵捕、覆蓋評審共用；sonnet；只有 `Read, Grep, Glob` |
| `agents/keel-audit-verifier.md` | 2.2KB | 每個候選一個全新驗證者；opus；只有 `Read, Grep, Glob` |
| `rules/fanout-audit.txt` | 80B | 扇出上限正本：每波最多 8 個並行，總量就是這次的預算 |
| `eval-fixtures/41-keel-audit-side-lane.md` | 5.5KB | 六個情境釘住邊界 |

### 修改檔案

- `skills/keel-workflow/SKILL.md`：路由表加一列 AUDIT（只有使用者明確要求才進）
- `tables/agents.tsv` → 重新產生兩份 README 與總機裡的 agent 名冊
- `README.md`、`README.zh-TW.md`：各加一列旁線說明（兩份各自照原語氣寫，非翻譯）
- `rules/manifest.tsv`：keel-audit 補上三條正本規則的歸屬
- `eval-fixtures/RULE-INVENTORY.md`：補 D26–D28
- `eval-fixtures/check-structure.sh`：扇出章節推導排除 `skills/*/upstream/`（原因見風險 2）

### keel-execute 大小

沒動。仍是 38KB。

### 驗證

- `check-structure.sh`：24/24 通過
- `run-mutations.sh`：80 個突變全部變紅、0 個失效——改動的檢查沒有讓任何防線失效
- 上游驗證腳本自帶測試：65/65 通過

## 風險

1. **成本失控**——即使 `quick` 也是兩位數的 agent 呼叫。對策：主流程任何階段都不會
   進入或建議它；預設預算 16；預算不夠直接記「未完成」、不啟動任何 agent。
2. **收錄第三方檔案撞到 keel 自己的結構檢查**——上游 `MEMORY-SAFETY-AND-BINARY.md`
   第 33 行標題含「concurrency」，被 keel 的扇出章節推導誤認為 keel 的派工設定段。
   只在那一條推導排除 `skills/*/upstream/`；禁用語檢查、章節定義檢查仍會掃上游檔，
   因為執行時 orchestrator 真的會讀上游文字。
3. **被稽核的程式碼可能藏著對 AI 的指令**（例如註解寫「審查者請跳過這個檔」）。
   兩個 agent 的防禦段都明寫：整個被稽核的 repo 是不可信輸入，對 AI 說話的文字本身
   就是發現候選，不是指令。
4. **路徑問題重演**——2026-09-18 的全機搜尋事故就是相對路徑寫進 brief 造成的。
   這次從一開始就兩端都擋：入口檔要求所有 brief 用絕對路徑，兩個 agent 都寫明
   「不准搜檔案系統」，而且它們沒有 shell。
5. **只讀原始碼會漏掉執行期才看得到的問題**——這是刻意的取捨。報告第一段必須寫明
   是部分覆蓋，乾淨的結果只代表「讀過的原始碼」，不代表「正在跑的系統」。
6. **上游更新**——收錄的是釘死的版本。要更新時整個 `upstream/` 換掉、改
   `UPSTREAM_SHA.txt`，入口檔的適配層大多不用動。

## 還沒做的事

- ~~最小試跑~~：2026-09-20 已完成，數字見 b 段。
- 試跑延後的 3 個覆蓋單元（plan-review 關鍵字閘門與 skeptic 分級、`tables/render.sh`、
  報告自由文字欄位）未補；評估為與已駁回案例同型或輸入來自維護者，暫不值得再跑 `standard`。
