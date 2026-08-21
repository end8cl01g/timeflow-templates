# /root/通用模版 — 通用模版套件（雙 agent 分工，token 最大化）

> **分工依據（arena.ai 實測硬體）**：1.9 GB RAM、無 swap、2 vCPU → **編譯/測試會 OOM，不能給 arena.ai**。
> arena.ai 只做「產出類」：查資料、寫文件、生媒體、轉資料（零編譯）。
> opencode（你）負責所有 Kotlin 實作、編譯、測試、APK。

## 目錄

```
/root/通用模版/
├── README.md              # 本導覽 + 分工
├── opencode/              ← 你（主要 agent）
│   ├── APK_FULL_REVERSE_REPORT.md        # 通用逆向分析報告模版（§9 任務拆分）
│   └── REVERSE_ENGINEERING_WORKFLOW.md   # 逆向執行流程
├── arena/                 ← arena.ai（研究與產出）
│   └── TASK_SLIP.md       # 研究/產出派工單（禁止編譯與測試）
└── 依賴檔案/
    ├── check.sh           # 驗證腳本（專案內 scripts/check.sh 的複本）
    └── detekt.yml         # 靜態分析設定（專案 config/detekt/ 的複本）
```

> 依賴檔案為「專案內對應檔案的複本」，供套用本模版的新專案參考；實際執行仍以專案內檔案為準。

## 分工原則（token 最大化）

| 工作 | 交給誰 | 理由（省 token） |
|------|--------|------------------|
| **網頁研究**（API 文件、規格、查證） | arena.ai | opencode 完全不用花 token 抓網/讀長文 |
| **文件/報告/簡報/表格撰寫** | arena.ai | 純產出，opencode 零成本 |
| **媒體**（圖示、示意圖、.pptx） | arena.ai | opencode 不做，零成本 |
| **資料轉換**（CSV/JSON/mock 資料/.ics 範例） | arena.ai | 重複性文字工作外包 |
| **任務規格起草**（§9 → TASK_SLIP 草稿） | arena.ai | 省 opencode 產文 token（opencode 只審） |
| **所有 Kotlin 實作** | opencode | 需要編譯驗證，arena 做不到 |
| **編譯 / 測試 / 檢查 / APK** | opencode | arena 沙盒 OOM 風險高 |
| **把 arena 產出合併進專案** | opencode | 唯一能驗證的人 |

> 關鍵：arena.ai 的產出**完全不觸發 opencode 的編譯/除錯迴圈** → 100% 節省那些 token。
> 反之，任何「讓 arena 寫 Kotlin 再給 opencode 編譯」的做法都不划算（arena 無法自驗，opencode 還是要修）。

## 協作流程

```
opencode
  ├─ 逆向 + 分析（opencode/ 模版）→ §7 差距 → §9 任務
  ├─ 把「研究/產出」子任務拆成 arena/TASK_SLIP.md 交付 arena.ai
  │        │
  │        ▼
  │   arena.ai（研究與產出，零編譯）
  │     └─ 產出 → /root/timeflow/arena-output/<任務ID>/
  │        ▲
  ├─ 審閱 arena 產出（只讀、少量 token）
  ├─ 功能實作 + 本機 check.sh + APK（全部自己跑）
  └─ 合併 arena-output 內容 → 完成
```

## 約束

- **arena.ai**：只做研究/產出/媒體/轉資料；**禁止** `gradlew` 編譯、測試、改 `composeApp/src/**`；產出放 `arena-output/<任務ID>/`。
- **opencode**：實作 + 編譯 + 測試全權；驗證 `cd /root/timeflow && ANDROID_HOME=/tmp/android-sdk ./scripts/check.sh`。
- 兩者皆：勿動 `/root/通用模版/**`、專案 `local.properties`。

## 工作區現況

- `apk_analysis_report.md`（根目錄）：Google Calendar / Clockify 實際分析（v1，歷史參考）。
- `arena-output/`：arena.ai 產出暫存（如產生）。
