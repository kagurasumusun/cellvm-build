AGENTS.md

# Windows CE LLVM Toolchain Integration

This repository workspace contains a long-running, research-heavy Windows CE
toolchain integration task.

The task spans:

* `kagurasumusun/llvm-project`
* `kagurasumusun/cellvm-sdk`
* `kagurasumusun/wince-docs-corpus`

The final objective is to make a Windows CE target build work using
`cellvm-sdk` and `llvm-project` together.

`cellvm-sdk` completion is an intermediate milestone.

It is NOT the final completion condition.

Do not declare the task complete until both `cellvm-sdk` and the required
Windows CE support in `llvm-project` have been implemented, integrated,
built, tested, reviewed, and cross-checked against the collected public
Windows CE evidence.

---

# 1. Core Mission

Complete the task end-to-end.

The required final state is:

```text
Windows CE public documentation
            │
            ▼
    wince-docs-corpus
            │
            ▼
      cellvm-sdk
            │
            ▼
      llvm-project
            │
      ┌─────┼──────────┐
      ▼     ▼          ▼
     libc  libc++   libunwind
      │     │          │
      └─────┼──────────┘
            ▼
       compiler-rt
            │
            ▼
 Windows CE target build
```

This diagram describes responsibility and dependency boundaries.
It does not imply that every component must directly depend on every other
component.

The final result must be an actual Windows CE target build, not merely a
collection of headers or a partially implemented SDK.

---

# 2. Repository Responsibilities

These responsibilities MUST remain separate.

## 2.1 cellvm-sdk

`cellvm-sdk` is the Windows CE development SDK surface.

Conceptually, it corresponds to the development portion of an OS SDK,
similar in role to the development/header package portion of a Linux
distribution.

It is NOT an operating-system reimplementation.

Its responsibilities may include:

* Windows CE headers
* target libraries/import libraries
* SDK definitions
* ABI-relevant declarations
* Windows CE target metadata
* documented target interfaces
* SDK-side compatibility layers
* POSIX compatibility layers that are intentionally implemented outside
  the Windows CE API surface

Do not move compiler implementation responsibilities into `cellvm-sdk`.

Do not implement Windows CE itself inside `cellvm-sdk`.

---

## 2.2 llvm-project

`llvm-project` provides the compiler and language/runtime implementation.

This includes, as applicable:

* LLVM
* Clang
* libc
* libc++
* libc++abi
* libunwind
* compiler-rt
* related compiler/runtime infrastructure

The LLVM-side implementation must use the Windows CE API where Windows CE
already provides the required operating-system functionality.

Do not confuse:

```text
Windows CE OS API
```

with:

```text
LLVM runtime/library implementation
```

Do not recreate Windows CE functionality inside LLVM merely because it makes
a particular build easier.

---

## 2.3 wince-docs-corpus

`wince-docs-corpus` is the project's persistent public-evidence corpus.

All collected documentation used for implementation decisions MUST be stored
there.

The corpus is not merely a collection of URLs.

Where practical, preserve:

* source URL
* archived URL
* source title
* publisher
* publication/update date
* retrieval date
* Windows CE generation/version
* API/component
* relevant declarations
* relevant behavior
* implementation implications
* confidence/authority classification
* notes about conflicting sources

---

# 3. Source-of-Truth Hierarchy

Windows CE behavior MUST be established from public evidence.

Use this priority order:

## Tier 1 — Primary authority

Prefer:

* Microsoft MSDN
* Microsoft Learn / Microsoft documentation
* official Microsoft-published Windows CE documentation
* official archived Microsoft documentation

## Tier 2 — Historical primary material

Use:

* Internet Archive / Wayback Machine
* archived official Microsoft documentation

Archived material is especially useful when the original Microsoft page is
no longer available.

## Tier 3 — Reputable public technical material

Use only when useful and legally/publicly accessible.

Examples include:

* established technical references
* reputable open-source projects
* established historical documentation

Treat these as secondary evidence, not automatically authoritative.

## Tier 4 — CEGCC reference material

The Windows CE portions of:

* `mingwrt`
* `w32api`

may be inspected.

Use them only for:

* comparison
* declaration checking
* value checking
* historical implementation clues
* identifying things that require further investigation

They do not override official Windows CE documentation.

---

# 4. Forbidden Research Sources

Do NOT use as evidence or implementation authority:

* Shared Source
* leaked source code
* leaked SDKs
* leaked documentation
* private Microsoft material
* non-public documentation
* Platform Builder
* Visual Studio-specific private/undocumented implementation details
* confidential material
* illegally obtained material

Do not attempt to obtain restricted material.

The purpose of this project is to reproduce documented Windows CE target
behavior using legal public information.

---

# 5. Windows CE Is Not Desktop Windows

This is a hard requirement.

Do NOT use ordinary desktop Windows information as a substitute for Windows CE
information.

In particular, do not use W32/W64/desktop Windows documentation to establish
Windows CE behavior.

Do not assume that an API existing on desktop Windows:

* exists on Windows CE
* has the same signature
* has the same structure layout
* has the same constants
* has the same ABI
* has the same error behavior
* has the same threading semantics
* has the same loader semantics
* has the same filesystem semantics
* has the same process semantics
* has the same synchronization semantics
* has the same Unicode behavior
* has the same CRT behavior

Names that look identical are not sufficient evidence.

When desktop Windows and Windows CE have similar APIs, independently verify
the Windows CE behavior.

---

# 6. Windows CE Generation Isolation

Windows CE generations MUST NOT be silently mixed.

For every generation-sensitive API, structure, constant, library, ABI rule,
or behavior:

1. Determine the Windows CE generation/version.
2. Identify documented availability.
3. Identify generation-specific differences.
4. Record the evidence.
5. Ensure the implementation does not accidentally contaminate one
   generation with another.

Explicitly review for generation contamination involving:

* APIs
* structures
* typedefs
* constants
* macros
* ABI
* calling conventions
* processor architecture
* Unicode behavior
* runtime behavior
* library availability
* synchronization primitives
* filesystem behavior
* process/thread behavior

If evidence cannot establish that two generations share behavior, do not
assume that they do.

---

# 7. Legacy Comments in cellvm-sdk

Comments in `cellvm-sdk` headers describing:

* old conventions
* old plans
* historical intentions
* obsolete compatibility rules
* superseded implementation requirements

are legacy information unless independently confirmed by current project
requirements or authoritative public evidence.

Do NOT automatically follow such comments.

When a comment is confirmed obsolete, remove or update it so that future
agents do not incorrectly interpret it as an active project requirement.

Before removing a comment, verify that it is actually obsolete.

Do not remove useful historical information merely because it is inconvenient.

---

# 8. Documentation-First Requirement

Before broad `llvm-project` integration begins, perform a comprehensive
documentation/evidence pass over the Windows CE interfaces required by the
target.

The initial workflow is:

```text
Collect evidence
      ↓
Store evidence
      ↓
Normalize
      ↓
Classify
      ↓
Cross-check
      ↓
Compare against cellvm-sdk
      ↓
Identify gaps
      ↓
Create implementation checklist
```

Do not consider the documentation phase complete merely because many pages
have been collected.

The collected evidence must be actionable.

---

# 9. Evidence-to-Implementation Traceability

Every significant Windows CE-specific implementation decision should be
traceable to evidence.

For each important item, establish:

```text
Public evidence
      ↓
Expected Windows CE behavior
      ↓
Current cellvm-sdk state
      ↓
Required change
      ↓
LLVM integration
      ↓
Test
```

Examples include:

* API declarations
* constants
* structures
* typedefs
* calling conventions
* ABI assumptions
* library names
* import symbols
* error handling
* Unicode interfaces
* synchronization APIs
* threading APIs
* process APIs
* filesystem APIs
* runtime APIs

Do not implement undocumented behavior merely because it appears convenient.

---

# 10. cellvm-sdk Gap Elimination

The objective is not merely to fix the first compiler error.

Systematically identify:

* missing headers
* missing declarations
* incorrect declarations
* incorrect constants
* incorrect typedefs
* incorrect structures
* incorrect macros
* missing libraries
* incorrect library symbols
* incorrect calling conventions
* incorrect ABI assumptions
* incorrect generation-specific definitions
* inconsistent declarations across headers
* missing target metadata
* missing compatibility components

For each category, compare:

```text
Windows CE evidence
vs.
cellvm-sdk
```

Repeat until no known documented requirement relevant to the target remains
unimplemented or inconsistent.

---

# 11. Header Placement Verification

Every declaration must be checked against its correct header.

Do not merely make compilation succeed by putting declarations into a
convenient header.

For each important declaration:

1. Determine the documented header.
2. Check the current `cellvm-sdk` location.
3. Verify dependencies.
4. Verify conditional compilation.
5. Verify generation applicability.
6. Verify architecture applicability.
7. Verify that the declaration does not contaminate unrelated headers.

Perform a dedicated final header-placement review.

---

# 12. POSIX Compatibility

Windows CE's native API must remain the Windows CE API.

Do NOT modify or distort the Windows CE API solely to make POSIX software
compile.

When POSIX compatibility is required:

```text
POSIX API
   ↓
cellvm-sdk POSIX compatibility layer
   ↓
Windows CE API
```

The compatibility layer should be separate from the native Windows CE API
definitions.

Do not masquerade POSIX interfaces as native Windows CE interfaces.

Do not alter documented Windows CE declarations to emulate POSIX.

---

# 13. LLVM Runtime Integration

For LLVM components such as:

* libc
* libc++
* libc++abi
* libunwind
* compiler-rt

the default strategy is to connect required functionality to the APIs
actually provided by Windows CE.

Where Windows CE provides the required operating-system primitive:

```text
LLVM runtime
    ↓
Windows CE API
```

Prefer that over inventing a second OS abstraction inside the LLVM target.

Where Windows CE does NOT provide a required primitive, investigate the
documented target constraints before implementing a fallback.

Do not silently substitute desktop Windows implementations.

Do not silently substitute Linux/POSIX implementations.

Do not assume that a desktop Windows backend is valid for Windows CE.

---

# 14. Research / Implementation Cycle

The project MUST operate as an iterative evidence-driven loop.

Primary cycle:

```text
Information collection
        ↓
Research
        ↓
Cross-check
        ↓
Implementation / correction
        ↓
Information collection
        ↓
Research
        ↓
Cross-check
        ↓
Implementation / correction
        ↓
repeat
```

Continue until the implementation has no known discrepancy against the
collected applicable evidence.

After implementation:

```text
Build
  ↓
Test
  ↓
Confirm
  ↓
Investigate
  ↓
Fix
  ↓
Build again
  ↓
Test again
  ↓
repeat
```

Never stop at the first successful build.

---

# 15. Checkpoint-Based Work

Divide the project into explicit checkpoints.

At minimum maintain checkpoints for:

1. Documentation corpus
2. Windows CE API inventory
3. cellvm-sdk header completeness
4. cellvm-sdk library completeness
5. cellvm-sdk consistency
6. generation separation
7. LLVM target integration
8. libc
9. libc++
10. libc++abi
11. libunwind
12. compiler-rt
13. cross-repository integration
14. target build
15. regression tests
16. final documentation cross-check

Each checkpoint must have:

```text
Requirement
Evidence
Current implementation
Gap
Change
Validation
Status
```

Do not mark a checkpoint complete merely because the code compiles.

---

# 16. Compare Before Editing

Whenever new documentation is collected:

1. Compare it against the existing corpus.
2. Compare it against the current implementation.
3. Identify the exact difference.
4. Determine whether the difference is:

   * missing implementation
   * incorrect implementation
   * obsolete implementation
   * generation-specific behavior
   * conflicting documentation
   * irrelevant information
5. Only then modify code.

Do not make changes merely because a source looks different.

Resolve conflicts through source authority, generation, context, and evidence.

---

# 17. Long-Running Task Execution

This is a long-running task.

Do not stop merely because:

* many files are involved
* many tests fail
* the repository is unfamiliar
* the first implementation fails
* the build takes a long time
* multiple iterations are required
* documentation is difficult to reconcile

Continue while useful work remains possible.

The agent should autonomously perform the next useful action within scope.

Do not wait for a user message merely because the next step is obvious.

---

# 18. Long-Running Task State

Do NOT put detailed temporary task state into this `AGENTS.md`.

Use the project execution plan and state files for task-specific progress.

Preferred files:

```text
PLANS.md
.agent/
    STATE.md
    CHECKLIST.md
    EVIDENCE.md
```

These files are operational state.

`AGENTS.md` contains durable rules.

This separation is intentional.

---

# 19. ExecPlan

For this task, maintain a living execution plan.

The plan should contain:

* objective
* repository boundaries
* research phases
* implementation phases
* dependencies
* checkpoints
* validation strategy
* acceptance criteria
* known risks
* unresolved questions

When the implementation strategy changes materially, update the plan before
continuing.

Do not allow the plan to become stale.

The plan is not a substitute for implementation.

---

# 20. Persistent State

Maintain `.agent/STATE.md`.

It should contain only current operational state.

Recommended structure:

```md
# Current State

## Objective

## Completed

## In Progress

## Current Evidence

## Current Gaps

## Decisions

## Validation

## Blockers

## Next Action
```

Keep this file concise.

When context becomes large, update the state before continuing.

When resuming work, inspect the repository, git state, plan, and state before
assuming previous conclusions remain valid.

---

# 21. No Fake Progress

Never claim that something is:

* complete
* tested
* verified
* documented
* compatible
* correct

unless there is evidence for that claim.

Never convert:

```text
"build command returned"
```

into:

```text
"Windows CE support is complete"
```

Never convert:

```text
"one configuration builds"
```

into:

```text
"all required Windows CE targets build"
```

Record the exact scope of validation.

---

# 22. Failure Loop Protection

Do not repeatedly execute an identical failed action without learning
something new.

If the same approach fails twice:

1. inspect the failure
2. identify the actual failure category
3. formulate a new hypothesis
4. inspect additional evidence
5. choose a materially different approach
6. test again

Failure categories should include, where applicable:

* source-code defect
* incorrect assumption
* missing SDK component
* incorrect header
* incorrect ABI
* generation mismatch
* build-system problem
* linker problem
* runtime problem
* test problem
* environment problem
* external dependency problem

Do not endlessly patch symptoms.

---

# 23. Long Build / Test Operations

Treat long-running builds and tests as asynchronous work.

When a build or test is running:

1. Start it.
2. Record the command and output location.
3. Identify safe independent work.
4. Perform independent research, source comparison, static inspection,
   test preparation, or other useful work.
5. Check the authoritative build/test result when appropriate.
6. Continue based on the result.

Do NOT repeatedly poll an unchanged process merely to appear active.

Do not perform conflicting edits against files that the active build requires.

Do not start unrelated destructive operations while a build is running.

---

# 24. Parallel Work

Independent work may be performed in parallel when the environment supports
it.

Good candidates include:

* documentation research
* independent source inspection
* test discovery
* static analysis
* unrelated component investigation

Do not parallelize conflicting edits to the same code.

Before applying findings from parallel work, reconcile them against the
current repository state.

---

# 25. Build Strategy

Do not rely on a single build command.

Use progressively broader validation:

```text
targeted component build
        ↓
targeted test
        ↓
cross-component build
        ↓
Windows CE target build
        ↓
runtime/library validation
        ↓
broader regression validation
```

Use the repository's actual supported build system and configuration.

Do not invent unsupported configurations merely to produce a green result.

---

# 26. Required LLVM Coverage

The Windows CE integration must explicitly investigate and address,
as applicable:

* libc
* libc++
* libc++abi
* libunwind
* compiler-rt
* Clang target support
* LLVM target/toolchain integration
* linker/toolchain integration
* target triples
* runtime library selection
* SDK discovery
* include paths
* library paths
* startup/runtime requirements

A successful `clang` invocation alone does NOT satisfy this requirement.

---

# 27. Cross-Repository Consistency

After modifying either repository, reconsider the other repository.

Examples:

```text
cellvm-sdk header change
        ↓
check LLVM include assumptions
        ↓
check runtime assumptions
        ↓
check build configuration
        ↓
rebuild
```

and:

```text
LLVM runtime change
        ↓
check required Windows CE API
        ↓
check cellvm-sdk declaration
        ↓
check library availability
        ↓
check documentation
```

Never treat the repositories as independent once integration begins.

---

# 28. Git Safety

Do not discard unrelated user changes.

Before editing:

* inspect `git status`
* inspect relevant diffs
* understand pre-existing modifications

Before finishing:

* inspect `git status`
* inspect `git diff`
* inspect `git diff --check`

Do not use destructive commands such as broad reset/revert operations unless
explicitly required and safe.

Do not create unrelated commits.

---

# 29. Push Policy

If repository changes must be pushed, use the GitHub authentication already
configured for the environment.

The environment variable:

```text
GITHUB_PAT
```

may be used for authenticated GitHub operations when the environment and
permissions permit it.

NEVER print the PAT.

NEVER write the PAT into files.

NEVER include the PAT in logs, commit messages, URLs, or final responses.

A successful push is NOT task completion.

After pushing:

1. verify the pushed repository state
2. update the corresponding submodule reference when applicable
3. continue the remaining integration/build/test/review work
4. perform final validation again

---

# 30. Submodules

If one repository references another as a submodule:

1. update the relevant repository
2. commit/push the referenced repository only when required by the task
3. update the parent submodule reference
4. verify the parent repository
5. continue testing

Do not treat a changed submodule pointer as proof that integration works.

---

# 31. No Premature Completion

The following are NOT completion:

* `cellvm-sdk` builds
* headers compile
* one LLVM component builds
* Clang starts
* a push succeeds
* a submodule pointer is updated
* one test passes
* one Windows CE generation works
* one architecture works

Completion requires the entire requested integration and final verification.

---

# 32. Definition of Done

The task may be declared complete only when all applicable requirements below
have evidence.

## Repository integration

* [ ] `cellvm-sdk` implementation is complete for the required target scope.
* [ ] `llvm-project` Windows CE integration is complete for the required
  target scope.
* [ ] The two repositories work together.
* [ ] Repository boundaries remain conceptually correct.

## Windows CE API

* [ ] Relevant public Windows CE documentation has been collected.
* [ ] Collected documentation has been stored in `wince-docs-corpus`.
* [ ] Documentation has been cross-checked.
* [ ] Applicable generation differences have been identified.
* [ ] Generation contamination has been checked.
* [ ] Header placement has been reviewed.
* [ ] Declarations have been checked.
* [ ] Constants have been checked.
* [ ] Structures have been checked.
* [ ] ABI/calling-convention assumptions have been checked.
* [ ] Relevant libraries/import symbols have been checked.

## cellvm-sdk

* [ ] Required headers exist.
* [ ] Required declarations exist.
* [ ] Declarations are in the correct headers.
* [ ] Required libraries exist.
* [ ] Required symbols are consistent.
* [ ] No known documented gaps remain within the target scope.
* [ ] No known internal inconsistencies remain.
* [ ] Obsolete header instructions have been removed or corrected.

## llvm-project

* [ ] Clang Windows CE target support is functional.
* [ ] libc Windows CE integration is addressed.
* [ ] libc++ Windows CE integration is addressed.
* [ ] libc++abi Windows CE integration is addressed where required.
* [ ] libunwind Windows CE integration is addressed where required.
* [ ] compiler-rt Windows CE integration is addressed where required.
* [ ] Toolchain/SDK discovery works.
* [ ] Include/library paths are correct.
* [ ] Target runtime selection is correct.
* [ ] Windows CE APIs are used where Windows CE provides the required
  functionality.
* [ ] Desktop Windows implementations have not been accidentally substituted.

## POSIX

* [ ] Native Windows CE API definitions remain native Windows CE definitions.
* [ ] POSIX compatibility is implemented as a separate compatibility layer
  where required.
* [ ] POSIX compatibility does not contaminate the native Windows CE API.

## Build

* [ ] Required Windows CE target builds succeed.
* [ ] Required compiler/runtime/library components build successfully.
* [ ] Link steps succeed where applicable.
* [ ] Target test builds complete without errors.
* [ ] Relevant tests pass.
* [ ] Relevant build configurations have been tested.

## Final review

* [ ] Final implementation has been compared against the collected evidence.
* [ ] Header placement has received a dedicated review.
* [ ] Windows CE generation separation has received a dedicated review.
* [ ] Cross-repository consistency has been reviewed.
* [ ] No known undocumented assumption has been introduced unnecessarily.
* [ ] No debug code remains.
* [ ] No unintended files are included.
* [ ] `git diff --check` passes.
* [ ] Final `git status` and diff have been reviewed.
* [ ] Original user requirements have been re-read and checked one by one.
* [ ] Push/submodule state has been verified if a push occurred.

The statement "all Windows CE public information contains zero discrepancies"
must be interpreted within the documented and relevant target scope actually
established by the evidence corpus.

Do not claim literal knowledge of undocumented or inaccessible information.

---

# 33. Completion Rule

Only after all Definition-of-Done requirements have been satisfied may the
task be reported as complete.

Do not report completion merely because the current implementation appears
reasonable.

The final decision must be based on:

```text
evidence
+
implementation
+
build
+
tests
+
cross-repository review
+
final documentation comparison
```

---

# 34. User Reporting

During autonomous execution, do not send routine progress reports.

Do not interrupt the task with unnecessary questions.

Report only when:

1. the requested work is complete, OR
2. a genuine external blocker makes further progress impossible, OR
3. a destructive/security-sensitive decision genuinely requires user input.

When reporting completion, provide:

* what was completed
* important repositories/components changed
* validation performed
* remaining limitations, if any

Do not claim more than was actually verified.

---

# 35. Autonomous Execution

Work autonomously within the scope of this task.

Do not ask for confirmation for routine implementation decisions.

Use this decision priority:

1. explicit user requirements
2. authoritative Windows CE public documentation
3. repository architecture/conventions
4. tests and observed behavior
5. secondary public evidence
6. engineering judgment

When sources conflict, do not silently choose one.

Record the conflict and resolve it using:

* source authority
* Windows CE generation
* publication context
* API/version context
* corroborating evidence

Ask for user input only when:

* a required decision is genuinely ambiguous,
* the decision is destructive or irreversible,
* required credentials/permissions are unavailable,
* or the task is blocked by information that cannot be obtained from
  permitted public sources or the repository.

---

# 36. Work Continuity

Do not intentionally introduce idle periods.

If a long-running command is executing, perform safe independent work where
possible.

If one investigation is blocked, continue another independent part of the
task.

If a test fails, investigate it.

If a source is unavailable, search permitted authoritative alternatives.

If an implementation path fails, develop a new hypothesis.

Always prefer the next useful, verifiable action over waiting.

---

# 37. Final Principle

The goal is not:

```text
make the compiler stop complaining
```

The goal is:

```text
documented Windows CE behavior
        ↓
correct cellvm-sdk
        ↓
correct LLVM integration
        ↓
correct runtime/library integration
        ↓
successful Windows CE target build
        ↓
successful tests
        ↓
final evidence cross-check
```

The project is complete only when the entire chain has been verified.
