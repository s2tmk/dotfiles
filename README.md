# dotfiles

開発環境の設定ファイルを管理するリポジトリ

## セットアップ

```bash
# 1. リポジトリをクローン
git clone git@github.com:s2tmk/dotfiles.git ~/dotfiles

# 2. セットアップを実行
cd ~/dotfiles
chmod +x install.sh   # 初回のみ実行権限を付与
./install.sh          # シンボリックリンクを自動生成
```

## 注意事項

既にシンボリックリンクが存在する場合はスキップ、ファイルが存在する場合は .bak にバックアップしてからリンクを作成する。
