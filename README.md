# Hammerspoon Workflow

macOS向けのHammerspoon設定。機能ごとにLuaファイルを分割して管理します。

## 機能

### Comic Hotkeys

Google Chromeの対象コミックビューアで操作を拡張します。

- コミックシーモア / BookLive
- `Q W E / A S D / Z X C / Space` → 次ページ
- `Shift + 上記` → 前ページ
- `Fn + 上記` → 通常入力
- `Cmd + Option + P` → Comic Hotkeys ON/OFF
- 長押しリピートを約0.45秒間隔に制御

### Terminal Capture

Terminalへ最後に一括投入したコマンド群と、その実行結果をまとめてクリップボードへコピーします。

1. Terminalで `Cmd + V` してコマンド群を貼り付ける
2. コマンドを実行する
3. `Cmd` を単独で押して離す
4. `英数`
5. `Space`
6. 今回のコマンド群 + 実行結果がクリップボードへ入る

### Window Auto Focus

最前面のウィンドウを閉じたり最小化したあと、フォーカスされている通常ウィンドウがなければ、現在のSpaceにある次の表示中ウィンドウへ自動でフォーカスします。

- ウィンドウを閉じた後の「どこにもフォーカスされていない」状態を補完
- 最小化後にも動作
- macOSがすでに正常に次のウィンドウへフォーカスしている場合は何もしない

## 構成

```text
hammerspoon-workflow/
├── init.lua
├── comic/
│   └── hotkeys.lua
├── terminal/
│   └── capture.lua
├── common/
│   └── key_sequence.lua
├── window/
│   └── focus.lua
├── install.sh
└── .gitignore
```

## 必要なもの

- macOS
- Hammerspoon
- Hammerspoonへのアクセシビリティ権限
- JISキーボード（Terminal Captureで`英数`キーを利用）

## インストール

```bash
chmod +x install.sh
./install.sh
```

既存の `~/.hammerspoon` は、インストール前に `~/.hammerspoon-backup-YYYYMMDD-HHMMSS` へバックアップします。

インストール後、Hammerspoonの **Reload Config** を実行してください。

## 方針

`init.lua` に機能を詰め込まず、機能単位でモジュールを分けます。

- Terminal関連: `terminal/`
- 漫画関連: `comic/`
- ウィンドウ関連: `window/`
- 複数機能から使う共通処理: `common/`
