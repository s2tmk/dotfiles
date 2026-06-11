---
name: learn
description: Distill a correction or hard-won insight from the current session into a one-line prevention rule, saved to the project MEMORY.md or promoted to skills/learned/ when it applies across projects. Invoke after a user correction, a repeated mistake, or when the user says /learn.
---

# Learn — フィードバックの永続化

セッション中の修正・発見を、次回以降の再発防止ルールに変換して保存する。

## 手順

1. **何が起きたかを1文で特定する**: ユーザーの修正、誤った仮定、繰り返したミス。
   ストーリーではなく「次に何を変えるか」を書く。
2. **保存先を判定する**:
   - このプロジェクト固有（用語、設計判断、データソース、レビュー手順）
     → プロジェクトの `MEMORY.md` に一行追記（既存形式に合わせる）
   - プロジェクト横断で再利用できるパターン（ツールの落とし穴、ワークフロー改善）
     → `~/.claude/skills/learned/<kebab-name>/SKILL.md` を新規作成
3. **ルール形式で書く**: 「Xのときは必ずY」「Zをしない — 代わりにW」。
   理由が自明でなければ括弧で一言添える。
4. **重複チェック**: 既存の MEMORY.md / learned/ に同じ趣旨があれば、新規作成せず
   既存の記述を強化・修正する。誤っていた古いルールは削除する。

## learned/ スキルの形式

```markdown
---
name: <kebab-case-name>
description: <いつ発動すべきかが分かる具体的なトリガー語入りの一文>
---

# <Title>

**Rule**: <一行のルール>
**Why**: <一行の理由>
**Example**: <該当する状況の最小例>
```

## 品質基準

- 保存する価値があるのは「次回の行動を変えるもの」だけ。感想・経緯・自明な一般論は保存しない。
- 1ファイル1ルール。肥大化したら分割する。
- 3ヶ月使われなかった learned スキルは削除候補（レビューして消す）。
