# 任務派工單（TASK SLIP）— 逆向分析與產出用途（arena.ai Agent Mode）

> **用途**：arena.ai 負責兩類工作——**① APK 逆向分析（decompile + 功能/UI）**、**② 研究與產出**。
> 沙盒只有 **1.9 GB RAM、無 swap、2 vCPU**：**Gradle/Kotlin 編譯與測試執行易 OOM，一律禁止**。
> 逆向分析為 jadx/apktool/aapt2/Python 字串萃取（輕量級），小中型 APK 可執行；**大型 APK（多 dex / >20MB）可能 OOM**，屆時須主動回報改由 opencode 接手。
> 編譯/測試/功能實作由主要 agent（opencode）在完整環境負責。

---

## 0. Agent 執行約束

- 模式：arena.ai agent mode，沙盒（有網際網路、無 git、可寫入工作區）。
- 工作區：與主要 agent 共用（寫入的**一般檔案會保留**；`build/`、快取、套件不會保留）。
- 工作區根目錄：`/root/timeflow`；逆向工作目錄一律在 `/tmp/apex/<目標>/`。
- **角色邊界（硬性）**：
  - ✅ APK 逆向分析（下載→解包→manifest/字串/資源/UI 分析，產出報告 md）。
  - ✅ 查資料 / 寫文件 / 生圖 / 轉資料（CSV/JSON）。
  - ❌ **禁止執行 Gradle / Kotlin / npm 大型編譯**（會 OOM）。
  - ❌ **禁止執行測試**（`*Test` / `check.sh`）。
  - ❌ 禁止修改 `composeApp/src/**`、`composeApp/build.gradle.kts`、`/root/通用模版/**`、`local.properties`。
- 產出統一放到：`/root/timeflow/arena-output/<任務ID>/`（最終報告 .md 可依派工指示複製到工作區根目錄）。

## 1. 允許的動作類型

| 類型 | 範例 | 產出 |
|------|------|------|
| **APK 逆向** | 下載→`unzip`→`aapt2` manifest→`jadx` 反編譯→`apktool` 資源→Python 字串萃取 | `arena-output/<任務ID>/`（報告 .md + 證據檔） |
| 網頁研究 | 官方 API 文件、規格、最新版本 | `.md`（附來源連結） |
| 文件撰寫 | 報告、規格、changelog、README 草稿 | `.md` / `.docx` / `.pptx` |
| 資料轉換 | 把證據字串轉表格、整理 mock 資料 | `.csv` / `.json` / `.md` |
| 範例檔案 | iCal `.ics`、假資料 | `.ics` / `.json` |
| 媒體 | 圖示、示意圖、簡報 | `.png` / `.pptx` |

## 2. 本次任務

- **任務 ID**：{{TASK-xx}}
- **類型**：{{①APK 逆向分析 / ②研究與產出 / 混合}}
- **目標**：{{一句話}}
- **目標 APK（逆向類必填）**：
  - 下載來源：{{apkpure / apkmirror / 自備路徑；若不指定，先搜尋「<app> apk」並挑最新穩定版}}
  - 套件名：{{com.example.app}}
- **交付物**：{{路徑 + 格式 + 內容重點}}
- **格式/語言**：{{繁體中文 / 表格 / 字數}}

## 3. APK 逆向分析流程（類型①）

> 完整流程與工具指令見 `/root/通用模版/opencode/REVERSE_ENGINEERING_WORKFLOW.md`；此處為精簡版。

```bash
mkdir -p /tmp/apex/<目標>/{download,apk-unpacked,jadx-out,apktool-out,evidence}
# 1) 下載（apkpure 若被 Cloudflare 擋，試 d.cdnpure.com 直連）
curl -sSLo /tmp/apex/<目標>/download/app.xapk "https://d.cdnpure.com/b/APK/<package>?version=latest"
# 2) APK→zip 解包
unzip -q <download/app.*> -d apk-unpacked   # .xapk 內含 base.apk，需再解出
# 3) Manifest（用環境 SDK 的 aapt2）
/tmp/android-sdk/build-tools/34.0.0/aapt2 dump badging <base.apk> > evidence/01_badging.txt
# 4) 反編譯（大型 APK 若 OOM：放棄並回報 opencode）
/tmp/apex/tools/jadx/bin/jadx -d jadx-out <base.apk>
# 5) 資源/UI
java -jar /tmp/apex/tools/apktool.jar d -f -o apktool-out <base.apk>
# 6) 字串萃取（Python，ASCII regex）
```
- 工具未裝時：下載 jadx / apktool 到 `/tmp/apex/tools/`（不進工作區）。
- 記憶體防護：大檔案優先只做「manifest + 字串 + 資源/UI」三項；`jadx` 反編譯放在最後，失敗即回報。
- 產出報告需含：應用概覽 / 權限對照 / 架構 / UI 畫面清單 / 資料庫 schema / API 端點 / **功能矩陣**（對照我方 app）/ 證據索引。格式對照 `/root/通用模版/opencode/APK_FULL_REVERSE_REPORT.md`。

## 4. 禁止的動作

- 執行 Gradle/Kotlin/npm 編譯或任何測試（`gradlew`、`check.sh`、`*Test`）。
- 大型 APK 的完整 `jadx` 反編譯若耗記憶體到卡死——**不要硬撐**，改做輕量分析並回報。
- 安裝大型依賴或啟動長駐服務。
- 修改 `composeApp/src/**`、`composeApp/build.gradle.kts`、`/root/通用模版/**`、`local.properties`。
- 覆蓋工作區既有檔案（除非派工明示）。

## 5. 完成準則

- [ ] 逆向類：`arena-output/<任務ID>/` 含報告 .md + 證據檔；報告含 §1–§6 與功能矩陣
- [ ] 產出類：交付物存在且符合 §2 規格
- [ ] 研究類附來源 URL
- [ ] 未執行任何編譯/測試

## 6. 回報格式

```text
任務 ID：
類型（逆向/產出）：
目標 APK（套件/版本/來源）：
交付物清單（路徑 + 格式）：
分析摘要（功能/UI 重點）：
記憶體/OOM 處理（若發生）：
已知限制（未查證/未完成項）：
```

---

*派工單版本：v5（逆向分析 + 研究產出）｜ 編譯/測試/功能實作由 opencode 負責。*
