# AGENTS.md

## 1. Mission

このリポジトリ群の最終目的は、以下の3リポジトリを連携させ、**Windows CE ターゲット向けの LLVM/C/C++ ツールチェーンおよびランタイムを、公開資料と実装の突き合わせに基づいて成立させること**である。

対象リポジトリ:

* `kagurasumusun/cellvm-sdk`
* `kagurasumusun/llvm-project`
* `kagurasumusun/wince-docs-corpus`

最終目標は `cellvm-sdk` 単体の完成ではない。

`cellvm-sdk` は必要な基盤であり、最終的には:

1. Windows CE の公開仕様と `cellvm-sdk` の内容が整合すること
2. `cellvm-sdk` に必要な不足項目が残っていないこと
3. `cellvm-sdk` 内に仕様上の不整合が残っていないこと
4. `llvm-project` が Windows CE を正しくターゲットとして扱えること
5. `libc`、`libcxx`、`compiler-rt`、`libunwind` 等の必要な LLVM コンポーネントが Windows CE の API / ABI / 実行環境に接続されること
6. Windows CE 向けビルドが成立すること
7. テストによって成立性を確認できること
8. 公開資料との突き合わせで未解決の不足・不一致が確認されないこと
9. Windows CE の世代差が混入していないこと

まで完了して初めて作業完了とする。

`git push`、Pull Request 作成、コミット作成、`cellvm-sdk` の完成は作業完了条件ではない。

---

# 2. Repository Roles

## 2.1 `cellvm-sdk`

`cellvm-sdk` は Windows CE ターゲット向けの開発用 SDK 相当物である。

Linux における `*-dev` パッケージ群に近い役割として扱う。

主な責務:

* Windows CE の公開 API に対応するヘッダ
* 必要な ABI / API 定義
* 必要なライブラリ・インポート情報
* Windows CE ターゲット向け開発に必要な定義・データ
* LLVM 側から Windows CE API を利用するための開発基盤
* 必要に応じた POSIX 互換層

`cellvm-sdk` は Windows CE OS 自体の再実装ではない。

### 禁止事項

以下を混同してはならない。

* SDK と OS 実装を混同しない
* Windows CE API と POSIX API を同一視しない
* LLVM の責務と SDK の責務を混同しない
* 通常の Windows の API / ABI / CRT を Windows CE にそのまま適用しない

---

## 2.2 `llvm-project`

`llvm-project` はコンパイラ、ランタイム、および C/C++ 標準ライブラリ等を提供する。

Windows CE 対応では、可能な限り Windows CE が実際に提供する API / ABI / 実行モデルへ接続する。

特に以下を対象として確認する。

* Clang
* LLVM
* `libc`
* `libcxx`
* `libcxxabi`
* `compiler-rt`
* `libunwind`
* 必要な target / driver / linker / runtime integration
* Windows CE 向けビルドシステムおよび target configuration
* その他、Windows CE ターゲット成立に必要な LLVM コンポーネント

LLVM 側に Windows CE API を再実装するのではなく、Windows CE が提供する機能を適切に利用する。

---

## 2.3 `wince-docs-corpus`

`wince-docs-corpus` は SDK ではない。

Windows CE に関する調査資料、公開仕様、確認済み情報、出典、世代区分、API / ABI / toolchain 関連情報を保存する**調査用資料コーパス**である。

収集した資料・調査結果・出典・整理情報は、原則としてここへ保存する。

このリポジトリに保存された資料を、実装の根拠を追跡できる形で管理する。

---

# 3. Terminology

以下の用語を厳密に区別する。

* **Windows CE**: Windows CE 系 OS / SDK / API / ABI を指す。
* **Windows CE generation**: CE 3.0、Windows CE .NET、Windows Mobile 系、Windows Embedded CE 等、資料上で区別される世代・製品系列。
* **SDK**: Windows CE アプリケーション・システム開発に必要な開発用定義・ライブラリ等。
* **POSIX compatibility layer**: Windows CE API を変更せず、POSIX API を別レイヤーとして提供する互換層。
* **LLVM runtime**: `compiler-rt`、`libunwind` 等、LLVM toolchain に関連するランタイム。
* **C library**: C 標準ライブラリ実装。
* **C++ standard library**: `libcxx` 等。
* **API**: Windows CE が公開するプログラミングインターフェース。
* **ABI**: calling convention、data layout、type representation、object format、linkage 等を含む二進互換性に関する仕様。
* **evidence**: 公開資料、ソースコード、ビルド結果、テスト結果等、主張を検証可能にする根拠。
* **corpus**: `wince-docs-corpus` に保存された調査資料群。

---

# 4. Windows CE Scope Boundary

Windows CE は通常の Windows と同一ではない。

そのため、通常の Win32 / Win64 / Windows Desktop / Windows Server / Windows NT 系資料を Windows CE の根拠として流用してはならない。

特に以下を無条件に Windows CE に適用してはならない。

* Windows Desktop API
* Windows Server API
* Win32 Desktop assumptions
* Win64 assumptions
* Windows NT kernel assumptions
* UCRT assumptions
* Desktop CRT assumptions
* Desktop loader assumptions
* Desktop process/thread semantics
* Desktop filesystem semantics
* Desktop synchronization semantics
* Desktop socket/network semantics
* Desktop registry semantics
* Desktop GUI assumptions
* Desktop linker/runtime assumptions

通常の Windows に関する情報が Windows CE と一致することが資料によって確認できない限り、Windows CE の仕様として採用しない。

---

# 5. Allowed Reference Exception

通常の Windows 資料を原則として調査対象外とする。

ただし、以下については例外的に参考情報として調査してよい。

* CEGCC の `mingwrt` の Windows CE 関連部分
* CEGCC の `w32api` の Windows CE 関連部分

これらは**仕様の一次根拠ではない**。

用途は:

* 値の照合
* 定義の存在確認
* 過去の実装方法の確認
* ABI / API 名称の補助確認
* 欠落候補の発見

に限定する。

CEGCC の実装を、そのまま Windows CE の仕様として採用してはならない。

---

# 6. Forbidden Information Sources

以下は調査対象外とする。

* Shared Source
* Visual Studio の非公開・制限付き資料
* Platform Builder の非公開資料
* 流出資料
* 非公開資料
* 不正取得資料
* ライセンス上利用できない資料
* 個人情報を含む資料
* 出所不明の内部資料

合法かつ公開された情報のみを使用する。

---

# 7. Evidence Priority

Windows CE に関する仕様確認では、原則として以下の優先順位で根拠を評価する。

## Priority 1

Microsoft の公式公開資料:

* MSDN
* Microsoft Learn
* Microsoft の公式公開ドキュメント
* Microsoft の公式アーカイブ
* Wayback Machine 上で確認可能な公式公開ページ

## Priority 2

信頼できる合法的な公開資料:

* 大手オープンソースプロジェクトの公開ソース
* 公式プロジェクトの公開ドキュメント
* 信頼できる技術資料
* 歴史的な Windows CE 開発資料

## Priority 3

補助的実装資料:

* CEGCC `mingwrt`
* CEGCC `w32api` の Windows CE 部分
* その他の公開オープンソース実装

Priority 3 の資料だけで仕様を確定しない。

複数の独立した資料を突き合わせ、矛盾がないことを確認する。

---

# 8. Source-of-Truth Rule

資料と実装が一致しない場合、即座に実装へ合わせてはならない。

まず:

1. 資料の世代を確認する
2. 資料の対象製品を確認する
3. API / ABI の対象を確認する
4. 同一事項を別の公式資料で確認する
5. `wince-docs-corpus` の既存資料と照合する
6. 現在の `cellvm-sdk` と照合する
7. 必要なら公開ソース実装と照合する
8. 差分を記録する
9. 根拠が確定してから実装を変更する

資料同士が矛盾する場合は、矛盾を隠さない。

世代差、製品差、対象 CPU 差、SDK 差、API availability 差などを調査する。

---

# 9. Historical Header Comments

`cellvm-sdk` のヘッダに存在するコメントに書かれた:

* 旧規約
* 過去の予定
* 未実装予定
* 暫定ルール
* 古い設計方針
* 古い TODO
* 古い互換性方針

は、現在の規約・仕様として扱わない。

公開資料および現在の設計に照らして不要となったコメントは削除する。

コメントに書かれている内容を根拠として新しい実装を作ってはならない。

ただし、歴史的資料として価値がある情報を完全に失うことが問題になる場合は、必要に応じて `wince-docs-corpus` に調査記録として保存する。

---

# 10. Architectural Boundary

## 10.1 Windows CE API

Windows CE の API を変更・再定義して POSIX に合わせてはならない。

Windows CE API は Windows CE の API として維持する。

## 10.2 POSIX

POSIX 互換性が必要な場合は、別の互換性層として `cellvm-sdk` 側に構築する。

概念的には:

```text
POSIX API
   |
   v
cellvm-sdk POSIX compatibility layer
   |
   v
Windows CE API
   |
   v
Windows CE
```

とする。

Windows CE API 自体を POSIX API に変形してはならない。

## 10.3 LLVM Runtime

`llvm-project` の runtime / standard library 実装は、可能な限り Windows CE が提供する API / ABI / runtime primitive を利用する。

不要な OS 再実装を LLVM 側へ持ち込まない。

---

# 11. Required Research Workflow

大規模な Windows CE 対応では、次のループを基本とする。

```text
情報収集
  ↓
資料整理
  ↓
仕様調査
  ↓
世代・対象範囲確認
  ↓
現在実装との突き合わせ
  ↓
差分抽出
  ↓
実装・修正
  ↓
ビルド
  ↓
テスト
  ↓
失敗分析
  ↓
追加情報収集
  ↓
再調査
  ↓
再突き合わせ
  ↓
再実装
  ↓
再テスト
```

差分が残っている限り継続する。

---

# 12. Checkpoint Method

情報収集を行った後は、いきなり実装を開始しない。

各領域ごとにチェックポイントを作る。

最低限、以下を分離して確認する。

* Target triple / target configuration
* CPU architecture
* ABI
* calling convention
* data layout
* object format
* linker assumptions
* Windows CE API
* C runtime
* C library
* C++ ABI
* `libcxx`
* `libcxxabi`
* `compiler-rt`
* `libunwind`
* threading
* synchronization
* process / thread APIs
* memory APIs
* filesystem APIs
* I/O APIs
* networking APIs
* time APIs
* locale / character APIs
* exception handling
* signal-related behavior
* startup / termination
* dynamic linking
* static linking
* headers
* import libraries / libraries
* SDK layout
* build-system integration
* tests
* generation boundaries

各項目について:

```text
公開資料
    ↓
仕様
    ↓
cellvm-sdk
    ↓
llvm-project
    ↓
実際のビルド
    ↓
テスト
```

の一貫性を確認する。

---

# 13. Difference-First Development

実装前に、以下を明示的に作る。

```text
Expected behavior
Current behavior
Difference
Evidence
Required change
Validation
```

実装後は同じ項目を再確認する。

「動いたから完了」ではなく、

「資料上期待される状態と実装状態の差分がなくなった」

ことを目標とする。

---

# 14. Cellvm SDK Completion Criteria

`cellvm-sdk` を完成扱いにするためには、少なくとも以下を確認する。

* 必要な公開 Windows CE API が欠落していない
* ヘッダ間に矛盾がない
* 定義の重複がない
* 型定義が適切である
* calling convention が適切である
* ABI に関する定義が適切である
* 必要なライブラリ情報が存在する
* 世代の異なる API が混在していない
* Desktop Windows の定義が誤って混入していない
* obsolete な内部コメントが現行仕様として残っていない
* LLVM が利用するために必要な情報が不足していない
* 公開資料との突き合わせで説明できない差分が残っていない

---

# 15. LLVM Windows CE Completion Criteria

`llvm-project` 側では、必要なコンポーネントについて Windows CE ターゲットとして成立することを確認する。

対象例:

* Clang target / driver
* LLVM target integration
* C runtime integration
* `libc`
* `libcxx`
* `libcxxabi`
* `compiler-rt`
* `libunwind`
* linker integration
* startup / termination
* exception handling
* threading / synchronization
* Windows CE API integration
* build configuration
* target-specific tests

必要性が確認されたコンポーネントについては、単に `#ifdef` を追加するだけで終わらせない。

Windows CE の実際の API / ABI と接続されていることを確認する。

---

# 16. Generation Isolation

Windows CE の世代差を最重要事項の一つとして扱う。

実装・資料を追加するときは必ず:

* 対象世代
* 対象製品
* 対象 CPU
* 対象 SDK
* API availability
* ABI compatibility
* 廃止時期

を確認する。

ある世代の API を別世代へ無条件に持ち込まない。

「Windows CE である」という理由だけで全世代共通と判断してはならない。

世代が特定できない資料は、仕様確定の根拠として慎重に扱う。

---

# 17. Header Review

ヘッダを変更した場合は、必ず以下を確認する。

* 定義を入れるヘッダが正しいか
* 別のヘッダに入れるべき定義を誤配置していないか
* include dependency が正しいか
* declaration / definition の責務が正しいか
* Windows CE 世代を誤って混ぜていないか
* Desktop Windows の定義を混入させていないか
* POSIX compatibility layer の定義と Windows CE native API の定義を混同していないか
* namespace / macro / typedef の衝突がないか
* include guard / pragma once 等が既存規約と整合するか

---

# 18. Testing Requirements

可能な限り、変更したコードだけではなく、依存する全体を検証する。

最低限:

1. configure / generation
2. compilation
3. linking
4. runtime library build
5. target-specific test build
6. unit tests
7. integration tests
8. ABI / API consistency checks
9. clean build
10. incremental build

を適用する。

テストが存在しない領域については、テスト可能な最小の検証ケースを作る。

---

# 19. Build Failure Policy

ビルドが失敗した場合、失敗を完了条件として扱わない。

必ず:

1. エラーを分類する
2. 最初の根本エラーを特定する
3. 依存する API / ABI / header / build configuration を確認する
4. 公開資料と照合する
5. 原因を仮説化する
6. 修正する
7. 再ビルドする
8. 修正による副作用を確認する

まで続ける。

同一の失敗を、情報を増やさず同じ方法で繰り返さない。

---

# 20. Failure Loop Protection

同じ方法による失敗を2回以上繰り返さない。

同一の失敗が再発した場合:

1. 失敗内容を比較する
2. 新しい情報を抽出する
3. 仮説を更新する
4. 別のアプローチを選択する
5. 再テストする

それでも進めない場合は、正確な blocker を記録する。

---

# 21. Parallel Work

独立した作業は可能な限り並列化する。

例えば:

* 資料収集
* API inventory
* header audit
* LLVM target investigation
* build-system investigation
* test inventory
* generation classification

などは、互いの依存関係を確認したうえで並列に調査する。

ただし、同じファイルを競合する形で複数作業に変更させない。

並列作業の結果は必ず統合後に相互検証する。

---

# 22. No Artificial Waiting

待機時間を作業として扱わない。

ビルド・テスト・調査の待ち時間がある場合は、可能な独立作業を進める。

ただし、同じ状態を無意味にポーリングしたり、ビルドプロセスを妨害したりしない。

利用可能な次の有益な作業がある場合は、それを実行する。

---

# 23. Long-Running Work

この作業は複数リポジトリにまたがる長時間作業である。

大規模な変更では `PLANS.md` の ExecPlan を使用する。

`PLANS.md` は単なる TODO リストではない。

実装者が途中の会話履歴を失っても、現在の作業状態、根拠、判断、残作業、検証方法を復元できる内容にする。

ExecPlan の作成・更新ルールは `PLANS.md` に従う。

---

# 24. Plan Maintenance

作業中に以下が発生した場合、`PLANS.md` を更新する。

* 新しい重要な発見
* 仕様上の矛盾
* 世代差の発見
* 設計変更
* API / ABI 方針の変更
* 実装方針の変更
* ビルド方式の変更
* テスト方針の変更
* 重要な失敗と原因
* 重要な決定
* 重要な blocker
* 完了した milestone

事実と判断を混同しない。

---

# 25. Documentation Corpus

Windows CE の資料を発見したら、可能な範囲で `wince-docs-corpus` に保存する。

資料には可能な限り以下を付与する。

* 出典 URL
* 出典タイトル
* 発行元
* 取得日
* 元資料の日付
* 対象 Windows CE 世代
* 対象製品
* 対象 CPU
* 対象 API
* 資料種別
* 信頼度 / 優先順位
* 関連する SDK / header / implementation
* 調査メモ

資料を単に保存するだけでなく、どの実装判断の根拠になったか追跡可能にする。

---

# 26. Web Research Rules

Web 調査では、検索結果のスニペットだけを根拠として採用しない。

可能な限り原資料を開き、該当箇所を確認する。

Wayback Machine を使用する場合は、元ページの URL と取得時点を記録する。

公式資料が複数存在する場合は、時系列と対象世代を確認する。

検索結果に通常 Windows の情報が混ざっている場合、それを Windows CE の資料として扱わない。

---

# 27. Git Rules

変更前に現在の状態を確認する。

最低限:

```bash
git status --short
git diff --stat
git diff --check
```

を利用する。

作業開始時点の既存変更を勝手に破棄しない。

他の作業による変更と自分の変更を区別する。

履歴を書き換える破壊的 Git 操作は、明確な理由がない限り使用しない。

---

# 28. Push Rules

push が必要な場合は、環境変数 `GITHUB_PAT` に設定されている認証情報を使用する。

認証情報を:

* ファイルへ保存しない
* ソースコードへ書き込まない
* ログへ出力しない
* コマンド履歴へ残さない
* `PLANS.md` や `wince-docs-corpus` に記録しない

PAT の値そのものを表示してはならない。

push は作業完了ではない。

push 後は必ず:

1. push 結果を確認
2. 関連するサブモジュールを確認
3. 必要ならサブモジュール更新
4. 作業ツリーを確認
5. build / test を再確認
6. 残りの計画を継続

する。

---

# 29. Submodules

サブモジュールが存在する場合、親リポジトリの状態だけで完了判定しない。

以下を確認する。

```bash
git submodule status
git submodule foreach --recursive 'git status --short'
```

必要な更新を行った場合は、親リポジトリ側の記録も確認する。

---

# 30. No False Completion

以下だけでは完了としない。

* パッチが適用できた
* コンパイルが一部成功した
* 一部テストが成功した
* `cellvm-sdk` が完成した
* LLVM の configure が成功した
* push が成功した
* CI が一部成功した
* エラー数が減った

完了には、全体の受け入れ条件を確認する必要がある。

---

# 31. Definition of Done

最終報告前に以下をすべて確認する。

## Research

* [ ] 公開 Windows CE 資料を調査した
* [ ] Microsoft 公式資料を優先して確認した
* [ ] Wayback 上の公式公開資料を必要に応じて確認した
* [ ] 補助資料との突き合わせを行った
* [ ] `wince-docs-corpus` に調査資料を保存した
* [ ] 資料の世代を分類した
* [ ] 資料間の矛盾を確認した

## `cellvm-sdk`

* [ ] 必要な API が不足していない
* [ ] ヘッダの配置が正しい
* [ ] ヘッダ間の不整合がない
* [ ] ABI 定義を確認した
* [ ] ライブラリ情報を確認した
* [ ] 旧コメント・旧規約を現行仕様として扱っていない
* [ ] Desktop Windows の誤混入がない
* [ ] Windows CE 世代汚染がない
* [ ] LLVM から利用可能な状態である

## `llvm-project`

* [ ] Windows CE target integration が成立している
* [ ] `libc` を確認した
* [ ] `libcxx` を確認した
* [ ] `libcxxabi` を必要に応じて確認した
* [ ] `compiler-rt` を確認した
* [ ] `libunwind` を確認した
* [ ] linker / driver integration を確認した
* [ ] Windows CE API への接続を確認した
* [ ] POSIX compatibility layer と Windows CE API を混同していない

## Build

* [ ] configure が成功する
* [ ] compile が成功する
* [ ] link が成功する
* [ ] runtime library build が成功する
* [ ] Windows CE target build が成功する
* [ ] clean build が成功する
* [ ] incremental build が成功する

## Tests

* [ ] relevant unit tests が成功する
* [ ] integration tests が成功する
* [ ] target-specific tests が成功する
* [ ] API / ABI consistency を確認した
* [ ] generation isolation を確認した

## Review

* [ ] 最終 diff を確認した
* [ ] `git diff --check` が成功した
* [ ] debug code が残っていない
* [ ] 不要なファイルが変更されていない
* [ ] ヘッダの記入先を再確認した
* [ ] Windows CE 世代汚染を再確認した
* [ ] 元の要求事項を最初から再確認した
* [ ] 未解決の差分がない
* [ ] push を完了条件と誤認していない

---

# 32. Completion Standard

最終的な完了条件は:

```text
Windows CE 公開資料
        ⇅
wince-docs-corpus
        ⇅
cellvm-sdk
        ⇅
llvm-project
        ⇅
Build
        ⇅
Tests
```

の間に、根拠のない仕様差分、不足、不整合、世代混入が残っていないことである。

「おそらく正しい」ではなく、可能な限り公開資料と実装・ビルド・テストによって確認する。

確認できない事項は、確認できた事実として報告しない。

---

# 33. Final Report

ユーザーへの最終報告では、少なくとも以下を明示する。

* 実装した内容
* 変更したリポジトリ
* 主要な設計判断
* 収集した資料の概要
* Windows CE 世代分離の確認結果
* `cellvm-sdk` の確認結果
* `llvm-project` の確認結果
* build 結果
* test 結果
* 残存する既知の問題
* push / commit の状態
* 完了条件の各項目の結果

検証していない事項を成功として記載しない。

---

# 34. Priority Order

複数の指示が衝突する場合、以下の順序で判断する。

1. 上位の実行環境・安全・権限ルール
2. ユーザーの明示的な要求
3. この `AGENTS.md`
4. `PLANS.md`
5. リポジトリ固有の既存規約
6. 実装上の慣例
7. 一般的な推測

不明な仕様を推測で確定しない。

---

# 35. Core Principle

このプロジェクトでは、

> **「ビルドが通ること」だけでは正しさの証明にならない。**

また、

> **「資料に書いてあること」だけでも現在の実装が正しいとは限らない。**

したがって、

```text
資料
+
世代
+
API
+
ABI
+
実装
+
ビルド
+
テスト
```

を相互に突き合わせる。

最終的に、Windows CE 向け実装として説明可能で、再現可能で、検証可能な状態を作る。
