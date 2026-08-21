# APK 逆向分析報告 — 通用模版（v3）

> **用途**：本文件是通用模版，套用到任一目標 APK 的完整逆向分析與任務拆分。
> **使用方式**：複製本檔 → 把 `{{佔位符}}` 與每節「填寫說明」換成實際資料 → 完成 §9 任務拆分後即可逐項交給 arena.ai agent mode 執行。
> 對照範例：先前針對 Google Calendar / Clockify 的實際產出見 `apk_analysis_report.md`（v1）與本模版的 v2 版本。

---

## 0. 填寫清單（開始前先對照）

- [ ] §1 應用概覽：版本/SDK/包體/混淆狀態
- [ ] §2 權限清單（`aapt2 dump badging`）
- [ ] §3 架構圖 + manifest 元件
- [ ] §4 UI 畫面清單（layout/Compose/fragment）
- [ ] §5 資料庫 schema（Room entity/DAO）
- [ ] §6 網路 API + OAuth scope + 請求模型
- [ ] §7 功能矩陣（目標 app × 我方 app 差距）
- [ ] §8 KMP 落地建議（優先序）
- [ ] §9 任務拆分（每項「待實作」拆成獨立任務）

---

## 1. 應用概覽（證據：aapt2 badging）

| 屬性 | 值 |
|------|-----|
| 套件 | `{{package.name}}` |
| 版本 | {{versionName}} |
| 版本碼 | {{versionCode}} |
| minSdk / target | {{minSdk}} / {{targetSdk}} |
| DEX | {{classes*.dex 數量}} |
| 包體 | {{APK / XAPK + 大小}} |
| 混淆 | {{R8 重度 / 輕度 / 無}} |

> 填寫指令：`aapt2 dump badging <apk>`，grep `^package:` 與 `sdkVersion/targetSdkVersion`。

## 2. 權限對照（證據：aapt2 badging 權限清單）

| 權限 | 用途（推測） | 我方 app 現況 |
|------|-------------|--------------|
| {{android.permission.X}} | {{用途}} | {{已有/待補/不需要}} |

> 填寫指令：`aapt2 dump badging <apk> | grep uses-permission`，去重排序後逐項填。
> 對照重點：dangerous 權限（日曆/位置/聯絡人/通知）與 FGS、鬧鐘、網路等 normal 權限。

## 3. 架構（證據：jadx 套件樹 + manifest components）

```
{{以文字樹呈現核心套件結構}}
manifest 元件：
  {{Activity / Service / Receiver / AppWidgetProvider 清單}}
```

> 填寫指令：
> - 套件樹：`jadx -d out <apk>` 後 `ls out/sources/<主套件>/`
> - 元件：`aapt2 dump xmltree <apk> --file AndroidManifest.xml | grep -E 'Raw: "' | grep -iE 'activity|widget|receiver|service'`
> 要點：辨識 UI 框架（XML Views / Compose / Fragment）、同步機制（SyncAdapter/WorkManager/FGS）、DI（Hilt/Koin/手動）。

## 4. UI 元件（證據：layout XML + strings.xml）

| 畫面 | 功能 | 證據來源 |
|------|------|----------|
| {{畫面名稱}} | {{功能}} | {{layout/fragment/activity + strings key}} |

> 填寫指令：
> - XML UI：`apktool d -f -o out <apk>`，看 `res/layout*`
> - Compose：grep `androidx.compose.runtime.Composable`
> - 畫面骨架：`res/values*/strings.xml` 中 screen/drawer/nav 相關 key
> 要點：列出主要導航項、每個畫面的核心互動（新增/編輯/刪除/切換）。

## 5. 資料庫（證據：jadx entity/DAO 欄位）

### {{App A}} 資料表
```kotlin
@Entity(tableName = "{{table}}")
data class {{Entity}}(
    // @ColumnInfo 欄位清單（混淆時由 DAO @Query SQL 或 AutoValue 推導）
)
```

### {{App B}} 資料表
同上。

> 填寫指令：
> - 未混淆：`jadx-out/sources/**/entities/*.java` 直接讀 `private final` 欄位
> - 已混淆：`**/dao/*Dao.java` 的 `@Query` SQL、`*Row.java` 的 `@ColumnInfo`
> 要點：每張表註明主鍵、nullable、JSON 儲存欄位（如 tagIds）、enum 儲存方式。

## 6. 網路 API（證據：字串萃取）

| 端點 | 用途 | OAuth scope / 認證 |
|------|------|--------------------|
| {{https://...}} | {{用途}} | {{scope}} |

> 填寫指令：
> - 端點：DEX 字串 `grep -oE 'https://[a-zA-Z0-9./_-]+'` 去重
> - OAuth：`grep -oE 'oauth2:[^ ]+'`
> - 請求模型：grep `class (Create|Start|Update|...)Request`
> 要點：區分主 API、報表 API、推送、OAuth 登入端點。

## 7. 功能矩陣：目標 app × 我方 app 差距

| 功能 | 目標 app | 我方 app 現況 | 行動 |
|------|----------|--------------|------|
| {{功能}} | ✅/— | {{✅已實作 / ⚠️部分 / —未實作}} | {{— / TASK-xx}} |

> 填寫指令：逐一對照功能（CRUD、計時、同步、通知、報表、小工具、權限、整合），「待實作/待補」項目必須在 §9 開出任務並回填 TASK-ID。
> 狀態標記：`✅已實作`（含證據）・`⚠️部分`（說明缺什麼）・`—`（未實作）。

## 8. KMP 落地建議（基於證據）

1. {{優先序 1：功能/權限/服務}}
2. {{優先序 2}}
3. …

> 填寫指令：依「我方 app 收益 × 實作成本」排序；平台服務（FGS/Widget/WorkManager/Location）標註對應權限與 manifest 元件需求。

---

## 9. 任務拆分（供主要 agent 實作；arena.ai 做研究/產出）

> **分工**：本節任務由**主要 agent（opencode）**實作（編譯+測試皆由 opencode 本機執行）。研究/文件/媒體等**產出類**子任務可拆給 **arena.ai**（見 `/root/通用模版/arena/TASK_SLIP.md`）；arena.ai 沙盒僅 1.9GB RAM，**不可**編譯或跑測試。
> **執行模式（arena.ai）**：沙盒（**有網際網路**、無 git、可寫入專案目錄）。
> **環境**：{{JDK 版本}}；Android SDK 位於 {{SDK 路徑}}（勿移動）；Gradle 依賴已快取。
> **執行前必讀**：`scripts/check.sh`、`composeApp/build.gradle.kts`、專案工作區淨化規則。

### 9.1 主要 agent 實作規範（每任務必守）
1. **工作區淨化**：只修改 `composeApp/src/**` 與 `composeApp/build.gradle.kts`；禁止寫入 `.apk`、`/tmp/**` 及合約外檔案。
2. **網路可用**：可下載新依賴；但新增依賴時**必須**同步更新 `gradle/libs.versions.toml`（版本 + library/plugin 條目），並在回報中註明新增的依賴與版本。優先使用既有 catalog 條目，避免版本衝突。
3. **最小改動**：新增檔案用獨立檔名；修改既有檔案只動必要處，禁止無關重構。
4. **驗證指令**（每任務完成必須全綠；由主要 agent 本機執行）：
   ```bash
   cd {{專案根目錄}} && ANDROID_HOME={{SDK路徑}} ./scripts/check.sh
   ```
   即 `compileKotlinJs` + `jvmTest` + `detekt` + `compileDebugKotlinAndroid`。
5. **回報格式**：任務 ID、新增/修改檔案清單、測試數、check.sh 輸出摘要、已知限制。
6. **產出接力**：需要研究/文件/媒體時，拆成子任務填 `/root/通用模版/arena/TASK_SLIP.md` 交付 arena.ai（產出放 `arena-output/<任務ID>/`），由 opencode 審閱合併。

### 9.2 任務總表

| ID | 任務 | 主要檔案（新增） | 依賴 | 驗證 |
|----|------|-----------------|------|------|
| TASK-01 | {{功能名}} | {{路徑}} | {{無/任務}} | {{compile / jvmTest / 手動}} |

> 填寫指令：由 §7「未實作」項目逐一開任務；優先拆成「純邏輯（commonMain 可測）+ 平台層（androidMain）」兩部分；全部任務預設可平行。

### 9.3 任務規格範本（每個任務複製一份）
```markdown
### TASK-{{xx}} — {{任務名稱}}
- **目標**：{{一句話，交付什麼}}
- **先讀**：{{既有檔案精確路徑清單}}
- **規格**：
  - {{行為/欄位/UI 規格，具體到可驗證}}
  - {{平台層 expect/actual 或 Room 遷移要求}}
- **範圍外**：{{明確不做什麼}}
- **驗證**：{{check.sh 通過 + 特定測試案例數 + 手動驗證點}}
```

### 9.4 任務類型與對應檔案慣例
| 類型 | 放置位置 | 測試位置 |
|------|----------|----------|
| 純邏輯（解析/計算/匯出） | `commonMain/data/<domain>/` | `commonTest/<同路徑>Test.kt` |
| 資料模型 + Repository | `commonMain/data/model/` + `data/repository/` | `commonTest/...RepositoryTest.kt` |
| Room 實作 | `androidMain/data/db/`（含 `MIGRATION`） | 依賴 compile |
| expect/actual 平台橋接 | `commonMain/platform/` + `androidMain|jsMain|jvmMain/platform/` | compile |
| UI Screen | `commonMain/ui/screens/` | compile |
| Widget / Service / Receiver | `androidMain/widget/` `service/` + manifest | compile + 手動 |

---

## 附錄：證據索引（模版）
```
/tmp/apex/{{app}}/evidence/
  01_*_badging.txt / 01_*_manifest_tree.txt   # 權限與元件
  02_strings.txt                                # DEX 字串庫
  02_jadx_*.log                                 # 反編譯日誌
  03_apktool_*.log                              # 資源解碼
  jadx-out/sources/**                           # 反編譯代碼
```
> 分析限制預設註記：混淆導致的欄位為推導；動態功能（Remote Config / 需登入）無法靜態還原。

---

*模版版本：v3 通用模版 ｜ 每份實例化報告應填寫 §0 檢查清單並註明分析日期與工具版本。*