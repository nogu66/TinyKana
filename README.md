# TinyKana

![Platform](https://img.shields.io/badge/platform-macOS%2012%2B-blue)
![License](https://img.shields.io/badge/license-MIT-green)

左右の Command キーを単体で押したとき、自動で英数 / かなを切り替える最小限の macOS メニューバーアプリです。

| キー操作 | 動作 |
|----------|------|
| 左 Command 単体 | 英数に切り替え |
| 右 Command 単体 | かなに切り替え |

他のキーと組み合わせた場合（Cmd+C など）は通常通り動作し、入力切り替えは発生しません。

## 必要要件

- macOS 12 以上
- Swift 5.9 以上（`swift --version` で確認）

## ビルド & 実行

```sh
git clone https://github.com/nogu66/TinyKana.git
cd TinyKana
make run
```

初回起動時はアクセシビリティ権限の許可ダイアログが表示されます。
**システム設定 → プライバシーとセキュリティ → アクセシビリティ** で TinyKana を許可してください。

## ログイン時に自動起動する

**システム設定 → 一般 → ログイン項目と機能拡張** を開き、
ビルドされた `TinyKana.app` を「ログイン時に開く」に追加してください。

## 終了

メニューバーのアイコンから **Quit** を選択してください。

## ライセンス

[MIT](LICENSE)
