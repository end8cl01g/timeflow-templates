# APK 逆向分析 — 優化 Prompt 與具體執行流程

> 目標：從指定 APK（Google Calendar、Clockify）完整還原**所有功能與 UI**，產出可供 KMP 實作的規格。
> 鐵律：**除最終分析報告 .md 外，任何下載/解包/暫存檔一律在 `/tmp`，嚴禁污染工作區。**

---

## 一、優化後 Prompt（取代原始 5 步驟草稿）

```text
# 角色
你是資深 Android 逆向工程師（精通 aapt/jadx/apktool/DEX/資源分析）
+ KMP 架構師（能把還原結果對映到 commonMain/androidMain/jsMain）。

# 目標
從下列 APK 完整還原「所有功能」與「所有 UI」：
  - Google Calendar: https://apkpure.com/tw/google-calendar/com.google.android.calendar
  - Clockify:        https://apkpure.com/clockify-%E2%80%94-time-tracker/me.clockify.android
產出兩份交付物：
  A. 每份 APK 的完整分析報告（權限 / 架構 / UI / 資料庫 / 網路 API / 功能矩陣）
  B. 一份「功能 vs 既有 TimeFlow 差距清單」（含實作建議與優先序）

# 硬性約束（不可違反）
1. 工作區淨化：所有下載、解壓、暫存、工具安裝一律放在 /tmp/apex/<app>/
   （或獨立 temp 目錄）。禁止在工作區建立任何非分析文件。
2. 僅允許把最終分析報告 *.md 寫入工作區（例如 docs/ 或專案根目錄）。
3. 每個階段完成需通過該階段驗證準則，未通過不得進入下一階段。
4. 所有指令必須冪等（可重跑）且可重現；關鍵輸出存成證據檔（Evidence）。

# 五階段執行框架
## Phase 1 — Brainstorm（澄清與選型）
- 釐清交付範圍：全部功能 or 指定子集？UI 細緻度（畫面截圖級 or 結構級）？
- 盤點工具鏈可行性，做 smoke test。
- 產出：工具鏈清單、風險清單、範圍定義。
- 驗證：每項工具能跑出最小產物（例如 aapt 能 dump manifest）。

## Phase 2 — Plan（拆解複雜度）
- 將任務拆成平行子任務：權限 / Manifest / UI(畫面+layout) / 資料庫(Room schema)
  / 網路 API(endpoint+model) / 背景服務 / Widget / 功能流程(state machine)。
- 產出：任務樹 + 里程碑（每里程碑有接受標準）。
- 驗證：接受標準可量化（例如「權限表 100% 對齊 manifest」）。

## Phase 3 — Detail（具體提取指引）
- 為每個子任務撰寫操作卡（Command Card）：明確指令 + 輸入 + 輸出檔 + 驗證方式。
- 產出：每子任務一頁操作卡，可獨立執行。
- 驗證：操作卡指令在乾淨目錄重跑成功（冪等）。

## Phase 4 — Execute（系統化執行）
- 依操作卡依序執行，證據留存：
  - Manifest：aapt dump
  - 字串/DEX：jadx + python 正則
  - 資源/UI：apktool decode + layout XML
  - 資料庫：SQL/Room 字串推導
  - API：URL 正則萃取
- 產出：各子任務證據檔 + 功能覆蓋矩陣（功能 x 證據 x 狀態）。
- 驗證：覆蓋矩陣 100%；無「未分析」欄位。

## Phase 5 — Refine（迭代收斂）
- 依結果與使用者回饋修正：補遺漏、修正誤判、加深細節。
- 產出：修正版報告 + 與上一版 diff。
- 驗證：diff 中無「倒退」（已確認功能未消失）。

# 輸出規範
- 報告 .md 需含：應用概覽 / 權限對照 / 架構圖(ASCII) / UI 元件清單 /
  資料庫 schema / API 端點表 / 功能矩陣 / 狀態機 / 對 KMP 的整合建議。
- 每項功能標注「證據來源」（檔名+行號/字串）與「可信度」（高/中/低）。
```

---

## 二、工作區淨化規則（Workspace Hygiene）

```
/tmp/apex/                        # 所有逆向工作根目錄（不在工作區）
  ├── tools/                      # 工具安裝（jadx / apktool）
  ├── google-calendar/
  │   ├── download/               # 原始 APK
  │   ├── apk-unpacked/           # APK 轉 zip 解壓
  │   ├── jadx-out/               # DEX 反編譯產物
  │   ├── apktool-out/            # 資源 decode
  │   └── evidence/               # 每子任務證據檔
  ├── clockify/                   # 同上結構
  └── (可選) report-build/        # 報告草稿暫存（最後才 copy .md 進工作區）

工作區 /root/timeflow/
  └── docs/REVERSE_ANALYSIS_*.md  # 唯一允許寫入的產物
```

禁止寫入工作區的項目（一律去 `/tmp`）：`.apk`、`.zip`、解壓目錄、反編譯輸出、Python 腳本、工具 binary、log。

---

## 三、具體執行流程（含指令）

### Step 0 — 環境準備（在 /tmp/apex/tools）
```bash
mkdir -p /tmp/apex/tools /tmp/apex/{google-calendar,clockify}
cd /tmp/apex/tools

# jadx（DEX→Java/Kotlin 可讀碼）
curl -sSLo jadx.zip https://github.com/skylot/jadx/releases/download/v1.5.0/jadx-1.5.0.zip
unzip -q jadx.zip -d jadx
export PATH=/tmp/apex/tools/jadx/bin:$PATH

# apktool（資源/layout/smali decode；需要 Java）
curl -sSLo apktool.jar https://github.com/iBotPeaches/Apktool/releases/download/v2.9.3/apktool_2.9.3.jar
# 使用：java -jar /tmp/apex/tools/apktool.jar d -f ...
```
驗證準則：`jadx --version`、`java -jar apktool.jar --version` 皆成功。

### Step 1 — 下載 APK（apkpure 可能為 .xapk，需解出主 .apk）
```bash
# 在 apkpure 頁面取得 .xapk/.apk 下載連結，下載到 /tmp/apex/<app>/download/
file /tmp/apex/<app>/download/*.xapk
unzip -q *.xapk -d ./download/unpacked   # .xapk 內含 split apks / base.apk
```
驗證：`file base.apk | grep "Android"`、簽章可讀。

### Step 2 — APK 轉 zip 並解包（不改變 APK 內容）
```bash
cd /tmp/apex/<app>
mkdir -p apk-unpacked
cd apk-unpacked
unzip -q ../download/base.apk
# 觀察: assets/ classes*.dex res/ AndroidManifest.xml resources.arsc
```
驗證：`classes*.dex` 存在、`AndroidManifest.xml` 存在。

### Step 3 — Manifest 解析
```bash
AAPT=/tmp/android-sdk/build-tools/34.0.0/aapt2
$AAPT dump badging /tmp/apex/<app>/download/base.apk > evidence/01_manifest_badging.txt
$AAPT dump xmltree /tmp/apex/<app>/download/base.apk --file AndroidManifest.xml > evidence/01_manifest_tree.txt
```
產出：套件/版本/minSdk/targetSdk/權限/元件清單。對照報告 §2 權限表。
驗證：權限數量與元件數與 `xmltree` 一致（100%）。

### Step 4 — DEX 反編譯與字串萃取
```bash
cd /tmp/apex/<app>
jadx -d jadx-out download/base.apk 2> evidence/02_jadx.log

# 字串萃取（DEX 原始字串，補 jadx 遺漏）
python3 - <<'EOF'
import glob, re
pat = re.compile(rb'[\x20-\x7e\u4e00-\u9fff]{4,}')
out = []
for dex in glob.glob('apk-unpacked/classes*.dex'):
    out += [m.decode('utf-8', 'ignore') for m in pat.findall(open(dex,'rb').read())]
open('evidence/02_strings.txt','w').write('\n'.join(sorted(set(out))))
EOF
```
產出：完整類別樹 + 字串庫（含 UI 文案、SQL、URL、權限、錯誤訊息）。
驗證：字串庫內含 report §6 的已知 API 端點（抽查）。

### Step 5 — 資源 / UI 解析
```bash
cd /tmp/apex/<app>
java -jar /tmp/apex/tools/apktool.jar d -f -o apktool-out download/base.apk
# 重點目錄
ls apktool-out/res/layout* 2>/dev/null          # layout XML（xml 型 UI）
ls apktool-out/res/values*/strings.xml          # 所有文案
grep -rEo 'https?://[^"< ]+' apktool-out/res/  # 資源內 URL
```
產出：每個畫面 → layout XML / Fragment / Compose 對映；UI 元件清單（畫面 + 互動）。
驗證：主要畫面（例如 Calendar 月/週/日、Clockify TimeTracker/Timesheet）皆有對應 layout/字串證據。

### Step 6 — 資料庫 schema 推導
```bash
cd /tmp/apex/<app>
grep -rhoE '(CREATE TABLE|ALTER TABLE)[^;\"]*' jadx-out | sort -u > evidence/06_sql.txt
grep -rhoE 'tableName *= *"[a-z_]+"' jadx-out | sort -u >> evidence/06_sql.txt
grep -rhoE '@Entity|@Dao|@Query' jadx-out -l > evidence/06_room_files.txt
```
產出：每張表（欄位/型別/主鍵）+ DAO 方法 → 對照報告 §5。
驗證：每張表欄位數與 report 一致。

### Step 7 — 網路 API 萃取
```bash
cd /tmp/apex/<app>
grep -rhoE 'https://[a-zA-Z0-9./_-]+' evidence/02_strings.txt | sort -u > evidence/07_endpoints.txt
grep -rhoE 'oauth2:[^ \"\x27]+' evidence/02_strings.txt | sort -u > evidence/07_oauth.txt
# 請求/回應 model（Retrofit/Moshi/Gson 型別）
grep -rhoE 'class (Create|Start|Split|Update)[A-Za-z]*Request' jadx-out | sort -u
```
產出：端點表 + OAuth scope + 請求模型。對照報告 §6。
驗證：`global.api.clockify.me`、`www.googleapis.com/calendar/v3/` 均在列。

### Step 8 — 功能流程 / 狀態機
```bash
cd /tmp/apex/<app>
# 從 jadx 產物抽 enum + 狀態
grep -rhoE 'enum class [A-Za-z]+ \{' jadx-out | sort -u > evidence/08_enums.txt
grep -rhoE '(ACTIVE|COMPLETED|PENDING|CONFIRMED|TENTATIVE|CANCELED|SYNCED)[,]' evidence/02_strings.txt | sort -u
```
產出：狀態集合 + 流程圖（計時器開始/暫停/停止、事件建立/編輯/刪除/週期）。
驗證：與 report §7 功能對映表一致。

### Step 9 — 功能覆蓋矩陣與報告
```bash
# 用 python 產出 markdown 矩陣：功能 x 證據檔 x 狀態(已分析/未分析/無此功能)
cd /tmp/apex
python3 tools_build_matrix.py ... > report-build/coverage.md
```
最終：把 `report-build/*.md` 複製進工作區 `docs/`（**唯一寫入工作區的動作**）。
驗證：覆蓋矩陣無「未分析」；`diff` 上一版報告確認無倒退。

---

## 四、交付物範本

| 章節 | 內容 | 對應 report |
|------|------|-------------|
| 1 應用概覽 | 套件/版本/SDK/大小/DEX | §1 |
| 2 權限對照 | 權限表 + 保護級別 + 用途 | §2 |
| 3 架構 | 分層 ASCII 圖 + 核心套件樹 | §3 |
| 4 UI 元件 | 畫面清單 + layout/Compose 對映 | §4 |
| 5 資料庫 | Room schema + DAO | §5 |
| 6 網路 API | 端點 + OAuth + 模型 | §6 |
| 7 功能矩陣 | 功能 x 兩 app x TimeFlow 差距 | §7 |
| 8 KMP 建議 | 統一模型/權限/DB/UI 落地 | §8 |
| 附錄 | 工具版本 + 證據索引 + 限制 | — |

---

## 五、驗證準則總表（Gate）

| Phase | 出口條件 |
|-------|----------|
| 1 Brainstorm | 範圍/工具/風險確定，smoke test 通過 |
| 2 Plan | 任務樹 + 里程碑接受標準 |
| 3 Detail | 每子任務操作卡可重跑 |
| 4 Execute | 覆蓋矩陣 100%，證據檔齊全 |
| 5 Refine | 無倒退 diff，報告定稿 |

---

*工作區淨化檢查：執行後 `git status` 只應出現 docs/*.md（或約定的報告檔）。*
