# PLANS.md

# Codex Execution Plans

このファイルは、このリポジトリ群で使用する **ExecPlan（実行計画）** の作成・更新・実行方法を定義する。

対象は長時間・多段階・複数リポジトリにまたがる作業であり、実装者が途中の会話履歴を失っても、ExecPlan だけから作業を再開できることを要求する。

このファイル自体は個別作業の計画ではない。

個別作業では、この形式に従った ExecPlan を作成・更新する。

---

# 1. Purpose

ExecPlan の目的は、複雑な作業を:

```text
調査
→ 設計
→ 実装
→ ビルド
→ テスト
→ 失敗分析
→ 修正
→ 再テスト
→ レビュー
```

まで一貫して実行できる、自己完結した実行仕様にすることである。

計画を単なる TODO リストにしてはならない。

実装者が:

* 何をするか
* なぜするか
* どの資料を根拠にするか
* どこを変更するか
* 何を変更してはいけないか
* どう検証するか
* 失敗した場合どう進めるか
* 何をもって完了とするか

を判断できる必要がある。

---

# 2. When to Use an ExecPlan

以下では ExecPlan を必須とする。

* 複数ファイルにまたがる変更
* 複数リポジトリにまたがる変更
* 新機能
* 大規模リファクタリング
* ABI / API 変更
* target 対応
* toolchain 対応
* runtime 対応
* build-system の大規模変更
* 1時間を超える可能性がある作業
* Windows CE 世代差の調査を伴う作業
* `cellvm-sdk` と `llvm-project` の接続作業
* 大量の公開資料との突き合わせ
* 原因不明のビルドエラーを伴う作業

単純な typo 修正などでは省略してよい。

---

# 3. ExecPlan Principles

## 3.1 Self-contained

ExecPlan は、可能な限り外部の会話履歴を必要としない。

必要なリポジトリ情報、用語、制約、判断、検証方法を記載する。

ただし、巨大な資料本文を ExecPlan にコピーしてはならない。

資料そのものは `wince-docs-corpus` に保存し、ExecPlan から参照する。

---

## 3.2 Evidence-driven

重要な設計判断には根拠を付ける。

根拠の優先順位は `AGENTS.md` の Evidence Priority に従う。

推測を事実として記載しない。

以下を明確に区別する。

* Fact
* Evidence
* Inference
* Decision
* Assumption
* Unknown

---

## 3.3 Decision-complete

実装者が途中で重要な設計判断をしなくても済む程度まで計画を具体化する。

ただし、調査前に存在しない事実を発明してはならない。

未知事項がある場合は:

```text
Unknown
↓
Required investigation
↓
Decision criteria
↓
Decision
```

として扱う。

---

## 3.4 Living Document

ExecPlan は作成して終了する文書ではない。

作業中に発見・判断・結果を更新する。

最低限、以下を継続的に更新する。

* Progress
* Surprises & Discoveries
* Decision Log
* Validation Evidence
* Outcomes & Retrospective

---

# 4. Required ExecPlan Structure

個別 ExecPlan は原則として以下の構造を持つ。

```markdown
# <Action-oriented title>

## Purpose / Big Picture

## Scope and Non-Goals

## Current State

## Desired End State

## Repository Map

## Evidence and Sources

## Architecture / Design

## Implementation Plan

## Dependency Order

## Validation Plan

## Failure and Recovery Strategy

## Progress

## Surprises & Discoveries

## Decision Log

## Validation Evidence

## Remaining Work

## Outcomes & Retrospective
```

必要な場合はセクションを追加してよい。

---

# 5. Purpose / Big Picture

数段落以内で:

* 現在何が問題か
* 何を変更するか
* なぜ必要か
* 完了すると何が可能になるか

を説明する。

Windows CE 対応では、例えば:

```text
cellvm-sdk が提供する Windows CE API / ABI 情報を LLVM 側から利用可能にし、
Clang / LLVM runtime / libc / libcxx / compiler-rt / libunwind 等を
Windows CE target としてビルド可能にする。

cellvm-sdk 自体の完成は中間目標であり、
最終的な成果物は cellvm-sdk と llvm-project を組み合わせた
Windows CE 向けの検証済み toolchain である。
```

のように、最終成果物を明確にする。

---

# 6. Scope and Non-Goals

明示的に対象範囲を定義する。

最低限:

### In Scope

* `cellvm-sdk`
* `llvm-project`
* `wince-docs-corpus`
* Windows CE 公開資料
* Windows CE target integration
* 必要な runtime integration
* API / ABI consistency
* generation isolation
* build
* tests

### Out of Scope

* Windows Desktop の一般的な互換対応
* Windows Server 対応
* Shared Source
* 非公開資料
* 流出資料
* Platform Builder の非公開資料
* Windows CE OS 自体の再実装

---

# 7. Current State

計画作成時点で実際のリポジトリを調査し、以下を記録する。

* 現在の branch
* commit
* dirty state
* submodule state
* 現在の build configuration
* 既存 target
* 既存 Windows CE support
* 既存 SDK contents
* 既存 tests
* 既知の build failures

推測で現在状態を記載しない。

---

# 8. Desired End State

完成状態を検証可能な形で記載する。

例えば:

```text
cellvm-sdk:
  - 必要な Windows CE API / ABI definitions が存在する
  - header / library layout が整合する
  - generation contamination がない

llvm-project:
  - Windows CE target configuration が存在する
  - compiler が target を認識する
  - required runtime components が build できる
  - libc / libcxx / compiler-rt / libunwind 等が必要な範囲で
    Windows CE API に接続される

validation:
  - clean build succeeds
  - target build succeeds
  - relevant tests succeed
  - documentation evidence agrees with implementation
```

---

# 9. Repository Map

実際の構造を確認してから記載する。

最低限:

```text
kagurasumusun/cellvm-sdk
kagurasumusun/llvm-project
kagurasumusun/wince-docs-corpus
```

について:

* 主要ディレクトリ
* target 関連コード
* runtime
* headers
* libraries
* tests
* build files
* documentation

を整理する。

存在を確認していないパスを計画に書かない。

---

# 10. Evidence and Sources

各重要な判断について、以下の形式で記録する。

```text
Claim:
Evidence:
Source:
Source date:
Windows CE generation:
Product:
CPU:
Confidence:
Implementation impact:
```

公式資料の場合は、その旨を明記する。

補助資料の場合は補助資料であることを明記する。

---

# 11. Windows CE Generation Matrix

Windows CE 対応では、世代を明示的に管理する。

必要に応じて以下のような表を作る。

| API / Feature | CE generation | Product | CPU | Evidence | cellvm-sdk | LLVM | Test |
| ------------- | ------------- | ------- | --- | -------- | ---------- | ---- | ---- |
| ...           | ...           | ...     | ... | ...      | ...        | ...  | ...  |

世代が不明な情報を「全 Windows CE 共通」として扱わない。

---

# 12. API / ABI Matrix

重要な API / ABI について:

| Item               | Official behavior | SDK representation | LLVM usage | Test |
| ------------------ | ----------------- | ------------------ | ---------- | ---- |
| Type               | ...               | ...                | ...        | ...  |
| Calling convention | ...               | ...                | ...        | ...  |
| Struct layout      | ...               | ...                | ...        | ...  |
| Function           | ...               | ...                | ...        | ...  |
| Constant           | ...               | ...                | ...        | ...  |

を作成する。

必要に応じて CPU / architecture ごとの差分も分離する。

---

# 13. Architecture / Design

設計は責務境界を明確にする。

基本構造:

```text
LLVM / Clang
    |
    +-- C library
    +-- C++ standard library
    +-- compiler-rt
    +-- libunwind
    |
    v
cellvm-sdk
    |
    +-- Windows CE native API
    |
    v
Windows CE
```

POSIX が必要な場合:

```text
POSIX application/API
        |
        v
cellvm-sdk POSIX compatibility layer
        |
        v
Windows CE native API
```

Windows CE native API を POSIX API に変更する設計は禁止する。

---

# 14. Implementation Plan

実装計画は subsystem 単位で記述する。

例:

```text
Phase A:
  Windows CE documentation corpus

Phase B:
  cellvm-sdk inventory

Phase C:
  cellvm-sdk corrections

Phase D:
  LLVM target integration

Phase E:
  libc integration

Phase F:
  libcxx / libcxxabi integration

Phase G:
  compiler-rt integration

Phase H:
  libunwind integration

Phase I:
  build-system integration

Phase J:
  target build

Phase K:
  comprehensive validation
```

実際の順序は依存関係の調査結果に基づいて変更してよい。

---

# 15. Information Collection Before Implementation

仕様調査が必要な作業では、原則として:

```text
collect
→ classify
→ cross-reference
→ inventory
→ identify gaps
→ decide
→ implement
```

の順番を守る。

実装しながら仕様を推測しない。

ただし、完全な情報収集が不可能な場合は、判明している範囲と未知範囲を明示して安全に進める。

---

# 16. Difference Ledger

重要な作業では Difference Ledger を作る。

形式:

| ID   | Requirement | Evidence | Current | Difference | Change | Validation | Status |
| ---- | ----------- | -------- | ------- | ---------- | ------ | ---------- | ------ |
| D001 | ...         | ...      | ...     | ...        | ...    | ...        | Open   |

各差分は:

```text
Open
→ Investigating
→ Decision made
→ Implemented
→ Tested
→ Verified
→ Closed
```

とする。

「実装した」だけでは Closed にしない。

---

# 17. Implementation Order

依存関係を優先する。

基本原則:

```text
Documentation
    ↓
API / ABI inventory
    ↓
SDK correctness
    ↓
Target configuration
    ↓
Low-level runtime
    ↓
C library
    ↓
C++ ABI / standard library
    ↓
Compiler runtime
    ↓
Build integration
    ↓
Tests
```

ただし、実際の repository dependency により順序を変更してよい。

変更した場合は Decision Log に理由を記録する。

---

# 18. Validation Plan

各 implementation item に対して:

```text
Static validation
Build validation
Link validation
Runtime validation
API validation
ABI validation
Generation validation
Regression validation
```

のうち必要なものを明示する。

テストが存在しない場合は、最小の再現可能な validation を定義する。

---

# 19. Build Matrix

可能な限り build matrix を作る。

例:

| Target     | CPU | Configuration | Component   | Result  |
| ---------- | --- | ------------- | ----------- | ------- |
| Windows CE | ... | ...           | Clang       | Pending |
| Windows CE | ... | ...           | libc        | Pending |
| Windows CE | ... | ...           | libcxx      | Pending |
| Windows CE | ... | ...           | compiler-rt | Pending |
| Windows CE | ... | ...           | libunwind   | Pending |

実際に存在しない target を捏造しない。

---

# 20. Test Matrix

| Area        | Test | Expected | Actual | Evidence | Status |
| ----------- | ---- | -------- | ------ | -------- | ------ |
| Target      | ...  | ...      | ...    | ...      | ...    |
| Header      | ...  | ...      | ...    | ...      | ...    |
| ABI         | ...  | ...      | ...    | ...      | ...    |
| libc        | ...  | ...      | ...    | ...      | ...    |
| libcxx      | ...  | ...      | ...    | ...      | ...    |
| compiler-rt | ...  | ...      | ...    | ...      | ...    |
| libunwind   | ...  | ...      | ...    | ...      | ...    |
| Generation  | ...  | ...      | ...    | ...      | ...    |

---

# 21. Failure and Recovery Strategy

テストまたは build が失敗した場合:

```text
1. Preserve the failure
2. Identify the first meaningful error
3. Classify the failure
4. Inspect surrounding implementation
5. Check source evidence
6. Form a hypothesis
7. Implement a targeted fix
8. Rebuild the smallest relevant target
9. Run regression validation
10. Update the plan
```

ログの最後のエラーだけを見て原因を決めない。

---

# 22. Failure Categories

失敗を可能な限り以下に分類する。

* Documentation mismatch
* Generation mismatch
* Header mismatch
* API mismatch
* ABI mismatch
* Type mismatch
* Calling convention mismatch
* Target configuration error
* Driver error
* Compiler error
* Linker error
* Runtime error
* Build-system error
* Test failure
* Environment failure
* Infrastructure failure

分類できない場合は `Unknown` として調査を続ける。

---

# 23. Failure Loop Protection

同じ修正を情報なしに繰り返さない。

同じ失敗が2回発生した場合:

```text
stop repeating
↓
compare failures
↓
extract new evidence
↓
change hypothesis
↓
change approach
↓
re-test
```

を行う。

---

# 24. Progress

`Progress` は作業中に更新する。

推奨形式:

```markdown
## Progress

### Phase A — Documentation

- [x] ...
- [x] ...
- [ ] ...

### Phase B — SDK

- [x] ...
- [ ] ...

### Phase C — LLVM

- [ ] ...
```

完了チェックは、検証結果が存在する項目にだけ付ける。

---

# 25. Surprises & Discoveries

当初の想定と異なる重要な発見を記録する。

例:

```markdown
## Surprises & Discoveries

- CE generation X と Y で同名 API の availability が異なることを確認。
- 既存 header の定義は別世代の資料由来だった。
- LLVM の既存 Windows path は Desktop Windows を前提としているため、
  CE 用に独立した integration が必要だった。
```

発見を埋もれさせない。

重要な発見は Decision Log と Difference Ledger に反映する。

---

# 26. Decision Log

重要な設計判断を記録する。

形式:

```markdown
## Decision Log

### D-001 — <decision title>

Date:
Decision:
Evidence:
Alternatives:
Reason:
Impact:
```

「何を選んだか」だけでなく「なぜ選んだか」を残す。

後から判断を覆す場合は、新しい Decision Entry を追加する。

古い決定を消して履歴を隠さない。

---

# 27. Assumptions

調査によって確認できていない仮定は明示する。

```markdown
## Assumptions

- A001: ...
- A002: ...
```

確認できたら:

```text
Assumption
→ Verified
```

へ変更する。

根拠のない仮定を最終完成条件に残さない。

---

# 28. Unknowns

未解決事項を明示する。

```markdown
## Unknowns

- U001: ...
- U002: ...
```

各 unknown について可能なら:

* required evidence
* investigation method
* blocking status

を記録する。

---

# 29. Validation Evidence

検証結果は具体的に記録する。

悪い例:

```text
Build passed.
```

良い例:

```text
Command:
<actual command>

Target:
<actual target>

Result:
exit code 0

Relevant output:
<short summary>

Date:
<date>

Artifact:
<artifact path or identifier>
```

実行していないコマンドを実行済みとして記録しない。

---

# 30. Documentation Cross-Check

Windows CE 対応では、実装完了前に以下を確認する。

```text
Official documentation
       ↓
Generation classification
       ↓
API / ABI inventory
       ↓
cellvm-sdk
       ↓
llvm-project
       ↓
Build
       ↓
Tests
```

どこかに差分があれば Difference Ledger に追加する。

---

# 31. Final Review

最終段階では、計画を最初から読み直す。

以下を確認する。

* 元の目的を満たしているか
* scope を逸脱していないか
* non-goal を侵食していないか
* 重要な資料を見落としていないか
* 世代差を誤って統合していないか
* API / ABI が整合しているか
* `cellvm-sdk` と LLVM の責務が混ざっていないか
* POSIX compatibility layer の位置が正しいか
* header の配置が正しいか
* build が成功しているか
* test が成功しているか
* 未解決差分がないか
* push を完了条件として扱っていないか

---

# 32. Definition of Done

ExecPlan 自体の完了条件:

* [ ] Purpose を満たした
* [ ] Scope を満たした
* [ ] 必要な公開資料を調査した
* [ ] 資料を `wince-docs-corpus` に保存した
* [ ] 世代分類を確認した
* [ ] API / ABI を確認した
* [ ] `cellvm-sdk` の差分を閉じた
* [ ] `llvm-project` の差分を閉じた
* [ ] 必要な runtime integration を完了した
* [ ] Build が成功した
* [ ] Test が成功した
* [ ] Regression validation が成功した
* [ ] 最終 diff をレビューした
* [ ] Header placement を再確認した
* [ ] Windows CE generation contamination を再確認した
* [ ] 既知の未解決事項を確認した
* [ ] 最終的な要求事項を再確認した

---

# 33. Completion Is Evidence-Based

以下を完了の根拠として単独では使用しない。

* 「実装した」
* 「CI が通った」
* 「configure が通った」
* 「一部テストが通った」
* 「push した」
* 「以前よりエラーが減った」
* 「他の Windows で動作した」

完了には、要求事項に対応する証拠が必要である。

---

# 34. Final Report

作業完了時には、ExecPlan から以下を復元できるようにする。

```text
What changed
Why it changed
What evidence justified it
What was tested
What passed
What failed
What was fixed
What remains
```

未検証事項を成功として報告しない。

---

# 35. Outcomes & Retrospective

完了後に簡潔な retrospective を記録する。

最低限:

* 実際に問題だった点
* 最も重要だった発見
* 想定と異なった点
* 有効だった検証方法
* 次回同様の作業で改善すべき点
* 今後も維持すべき資料 / test / invariant

を記録する。

---

# 36. Repository-Specific Rule

このプロジェクトでは、`PLANS.md` よりも `AGENTS.md` のほうが恒久的な作業規約を保持する。

そのため、ExecPlan の中に `AGENTS.md` と同じルールを大量にコピーしない。

以下の役割分担を維持する。

```text
AGENTS.md
  ↓
恒久的な作業規約・境界・検証原則

PLANS.md
  ↓
ExecPlan の書き方・維持方法

個別 ExecPlan
  ↓
今回の具体的な調査・設計・実装・検証

wince-docs-corpus
  ↓
Windows CE の実資料・証拠・調査記録
```

---

# 37. Plan Continuation

長時間作業では、現在の作業を停止して次のセッションへ移行する可能性を考慮する。

その場合でも、次の実行者が:

1. ExecPlan を読む
2. Progress を読む
3. Decision Log を読む
4. Difference Ledger を読む
5. Validation Evidence を読む
6. 現在の repository state を確認する
7. Remaining Work の先頭から継続する

ことで作業を再開できる状態にする。

会話履歴に依存しない。

---

# 38. No Silent Scope Changes

作業中に当初の計画より大きな変更が必要になった場合は、黙って scope を変更しない。

以下を更新する。

* Scope
* Design
* Implementation Plan
* Decision Log
* Validation Plan

変更理由を記録する。

---

# 39. No Premature Completion

中間成果物が完成しても、最終目標が未達なら完了扱いにしない。

特に:

```text
cellvm-sdk completed
```

は:

```text
Windows CE toolchain completed
```

を意味しない。

また:

```text
LLVM target compiles
```

も:

```text
libc/libcxx/compiler-rt/libunwind and required runtime integration
are fully validated
```

を意味しない。

---

# 40. Final Principle

このプロジェクトの ExecPlan は、

> **「何を変更するか」を記録する文書ではなく、「公開された Windows CE の事実から、検証可能な実装状態へ到達するための再現可能な実行仕様」**

として扱う。

最終状態は:

```text
Evidence
   ↓
Specification
   ↓
Difference
   ↓
Implementation
   ↓
Build
   ↓
Test
   ↓
Review
   ↓
Verified Completion
```

で説明できなければならない。
