# gemini-patch

一鍵把 Gemini CLI 內部 `DEFAULT_MAX_ATTEMPTS` 改成 `10000`。

## 檔案

- `apply.sh`: Linux / macOS 使用
- `apply.bat`: Windows 使用

## 使用方式

### Linux / macOS

```bash
cd gemini-patch
chmod +x apply.sh
./apply.sh
```

### Windows (cmd)

```bat
cd gemini-patch
apply.bat
```

## 這個 patch 會改哪裡

- `.../@google/gemini-cli-core/dist/src/utils/retry.js`
- `.../@google/gemini-cli-core/dist/src/utils/retry.d.ts`（若存在）

## 注意

- 你更新 `@google/gemini-cli` 後，patch 可能被覆蓋，要再跑一次腳本。
- 腳本會先建立 `.bak` 備份檔。
