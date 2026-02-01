# スキル候補 統合・整理案

**作成日**: 2026-02-01
**目的**: 25件以上のスキル候補を整理・統合し、5-10件程度に厳選

## 現状の問題

- スキル候補が25件以上溜まっている
- 重複・類似機能が多い
- 優先度が不明確

## 統合案

### カテゴリ1: ドキュメントレビュー系（5件 → 1件に統合）

**統合前:**
1. technical-doc-reviewer
2. document-section-reviewer
3. chapter-guideline-checker
4. technical-book-chapter-analyzer
5. draft-overall-review（cmd_007で追加）

**統合後: `technical-book-reviewer`**

| 項目 | 内容 |
|------|------|
| 名前 | technical-book-reviewer |
| 説明 | 技術書・ドキュメントの包括的レビュースキル |
| 機能 | セクション別レビュー、全体構成チェック、ガイドライン準拠確認、改善提案生成 |
| 出力 | 優れている点、問題点（severity付き）、改善提案、チェックリスト |

---

### カテゴリ2: 図版作成系（9件 → 2件に統合）

**統合前:**
1. radar-chart-generator
2. data-visualization-graph-generator
3. data-chart-creator
4. technical-diagram-artist
5. book-figure-generator
6. business-diagram-creator
7. technical-book-figure-generator
8. svg-diagram-generator
9. technical-flowchart-generator

**統合後:**

#### 2a. `chart-generator`
| 項目 | 内容 |
|------|------|
| 名前 | chart-generator |
| 説明 | データ可視化グラフの自動生成 |
| 機能 | 棒グラフ、円グラフ、レーダーチャート、折れ線グラフ |
| 特徴 | matplotlib、300dpi、日本語対応 |

#### 2b. `diagram-generator`
| 項目 | 内容 |
|------|------|
| 名前 | diagram-generator |
| 説明 | 技術図・フロー図・構成図の自動生成 |
| 機能 | アーキテクチャ図、フローチャート、比較表、組織図 |
| 特徴 | SVG/PNG、300dpi、書籍印刷対応 |

---

### カテゴリ3: Draft作成・改善系（4件 → 1件に統合）

**統合前:**
1. chapter-draft-generator
2. technical-content-enhancer
3. technical-book-draft-improver
4. draft-version-manager

**統合後: `draft-improver`**

| 項目 | 内容 |
|------|------|
| 名前 | draft-improver |
| 説明 | 調査報告に基づくdraft作成・改善 |
| 機能 | 表現の客観化、数値具体化、図版追加、ガイドライン準拠 |
| ワークフロー | 調査 → draft作成 → 図版追加 → レビュー |

---

### カテゴリ4: 図版レビュー系（8件 → 1件に統合）

**統合前:**
1. figure-guideline-checker
2. figure-reviewer（複数）
3. technical-book-figure-reviewer
4. figure-quality-reviewer
5. figure-review-qa
6. figure-review-qa-workflow

**統合後: `figure-reviewer`**

| 項目 | 内容 |
|------|------|
| 名前 | figure-reviewer |
| 説明 | 図版の5軸レビュー |
| 機能 | 数値正確性、文脈の流れ、シンプルさ、情報鮮度、視覚品質 |
| 出力 | 問題点リスト（severity付き）、改善提案 |

---

### カテゴリ5: 用語・モデル名修正系（2件 → 1件に統合）

**統合前:**
1. model-name-corrector
2. technical-term-unifier

**統合後: `term-corrector`**

| 項目 | 内容 |
|------|------|
| 名前 | term-corrector |
| 説明 | 用語・モデル名の一括検索・修正 |
| 機能 | 実在しないモデル名検出、一括修正、draft+図版の整合性確認 |

---

### カテゴリ6: 数値データ監査（1件 → 維持）

**統合後: `numeric-data-auditor`**

| 項目 | 内容 |
|------|------|
| 名前 | numeric-data-auditor |
| 説明 | 数値データの根拠・出典チェック |
| 機能 | 全数値抽出、出典有無確認、社内実測値明記チェック |
| 出力 | 根拠不明な数値リスト、改善提案 |

---

### カテゴリ7: 図版テキスト修正（1件 → 維持）

**統合後: `figure-text-corrector`**

| 項目 | 内容 |
|------|------|
| 名前 | figure-text-corrector |
| 説明 | 図版内テキストの修正・再作成 |
| 機能 | matplotlib再作成、スタイル踏襲、テキストのみ修正 |
| 特徴 | 300dpi、日本語対応 |

---

## 統合後のスキルリスト（8件）

| # | スキル名 | カテゴリ | 優先度 |
|---|----------|----------|--------|
| 1 | **technical-book-reviewer** | レビュー | 高 |
| 2 | **chart-generator** | 図版作成 | 高 |
| 3 | **diagram-generator** | 図版作成 | 高 |
| 4 | **draft-improver** | Draft作成 | 高 |
| 5 | **figure-reviewer** | 図版レビュー | 高 |
| 6 | **term-corrector** | 用語修正 | 中 |
| 7 | **numeric-data-auditor** | データ監査 | 高 |
| 8 | **figure-text-corrector** | 図版修正 | 中 |

---

## 統合のメリット

1. **覚えやすい**: 25件 → 8件で管理しやすい
2. **重複排除**: 類似機能を統合して一貫性向上
3. **カテゴリ明確**: 用途別に整理されて選びやすい
4. **拡張性**: 各スキル内でサブ機能として拡張可能

---

## 次のステップ

1. 殿に統合案を承認いただく
2. 承認後、各スキルの詳細設計書を作成
3. スキル実装（優先度順）

---

## 殿への確認事項

1. この統合案でよいか？
2. 追加で必要なスキルはあるか？
3. 優先度の調整は必要か？
