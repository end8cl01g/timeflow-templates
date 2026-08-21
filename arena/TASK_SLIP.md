# 任務派工單（TASK SLIP）— 研究與產出用途（arena.ai Agent Mode）

> **用途**：arena.ai 沙盒只有 **1.9 GB RAM、無 swap、2 vCPU**，大型編譯（Gradle/Kotlin）與測試執行易 OOM。
> 因此 arena.ai **只負責「產出類」任務**：查資料、寫文件、生媒體、轉資料——完全不碰編譯與測試。
> 編譯/測試/功能實作由主要 agent（opencode）在完整環境負責。

---

## 0. Agent 執行約束

- 模式：arena.ai agent mode，沙盒（有網際網路、無 git、可寫入工作區）。
- 工作區：與主要 agent 共用（寫入的**一般檔案會保留**；`build/`、快取、套件不會保留）。
- 工作區根目錄：`/root/timeflow`
- **角色邊界（硬性）**：
  - ✅ 查資料 / 寫文件（md、docx、xlsx、pptx、pdf）/ 生圖 / 轉資料（CSV/JSON）。
  - ❌ **禁止執行 Gradle / Kotlin / npm 大型編譯**（會 OOM）。
  - ❌ **禁止執行測試**（`*Test` / `check.sh`）。
  - ❌ 禁止修改 `composeApp/src/**` 的原始碼與 `composeApp/build.gradle.kts`、`/root/通用模版/**`。
- 產出統一放到：`/root/timeflow/arena-output/<任務ID>/`（避免污染專案根；opencode 會再合併）。

## 1. 允許的動作類型

| 類型 | 範例 | 產出 |
|------|------|------|
| 網頁研究 | 官方 API 文件、規格、最新版本 | `.md`（附來源連結） |
| 文件撰寫 | 報告、規格、changelog、README 草稿、任務說明 | `.md` / `.docx` / `.pptx` |
| 資料轉換 | 把證據字串轉表格、整理 mock 資料 | `.csv` / `.json` / `.md` |
| 範例檔案 | iCal `.ics`、設定檔、假資料 | `.ics` / `.json` |
| 媒體 | 圖示、示意圖、簡報 | `.png` / `.pptx` |
| 分析 | 純文字邏輯（不含編譯）的草稿 | `.md`（附推理） |

## 2. 本次任務

- **任務 ID**：{{TASK-xx}}
- **目標**：{{一句話}}
- **交付物**：{{路徑 + 格式 + 內容重點}}
- **研究範圍**：{{網址/主題清單}}
- **格式/語言**：{{繁體中文 / 表格 / 字數}}

## 3. 禁止的動作

- 執行編譯（`gradlew`、`npm build` 等）或測試。
- 安裝大型依賴或啟動長駐服務（除非極輕量）。
- 修改 `composeApp/src/**`、`composeApp/build.gradle.kts`、`/root/通用模版/**`、`local.properties`。
- 覆蓋工作區既有檔案（除非派工明示）。

## 4. 完成準則

- [ ] 交付物存在於 `arena-output/<任務ID>/`
- [ ] 內容符合 §2 規格（格式/語言/篇幅）
- [ ] 研究類附來源 URL
- [ ] 不需編譯驗證（純產出）

## 5. 回報格式

```text
任務 ID：
交付物清單（路徑 + 格式）：
研究/資料來源（URL 清單）：
內容摘要：
已知限制（未查證/未完成項）：
```

---

*派工單版本：v4（研究與產出）｜ 編譯/測試/實作由 opencode 負責。*
