# Windows CE LLVM Integration

## Mission

Complete the Windows CE toolchain integration across:

* `kagurasumusun/llvm-project`
* `kagurasumusun/cellvm-sdk`
* `kagurasumusun/wince-docs-corpus`

The final objective is a working Windows CE target build using
`cellvm-sdk` and `llvm-project`.

`cellvm-sdk` completion is an intermediate milestone, not the final goal.

Do not declare completion until the required Windows CE integration of both
repositories has been implemented, built, tested, reviewed, and
cross-checked against the applicable public Windows CE evidence.

---

## Repository Responsibilities

### cellvm-sdk

`cellvm-sdk` provides the Windows CE development SDK surface.

It is conceptually comparable to the development/header/library portion of
an OS development package.

It is NOT an operating-system reimplementation.

Do not move compiler, runtime, or operating-system implementation
responsibilities into `cellvm-sdk` merely to make a build succeed.

### llvm-project

`llvm-project` provides the compiler and C/C++ runtime/library
implementation, including as applicable:

* LLVM
* Clang
* libc
* libc++
* libc++abi
* libunwind
* compiler-rt

Keep the responsibilities of `cellvm-sdk` and `llvm-project` separate.

Where Windows CE provides an operating-system API, LLVM runtime components
should connect to that API rather than reimplementing the operating system.

### wince-docs-corpus

`wince-docs-corpus` is the persistent evidence corpus.

Store collected Windows CE research and implementation-relevant evidence
there.

---

## Windows CE Evidence Policy

Prefer:

1. Microsoft MSDN
2. Microsoft Learn
3. Official Microsoft-published documentation
4. Official Microsoft documentation archived through Wayback Machine
5. Reputable legal public technical sources

CEGCC `mingwrt` and the Windows CE portions of `w32api` may be used only as
secondary references for comparison and value/declaration checking.

Do not treat secondary sources as authoritative over official Windows CE
documentation.

Do not use:

* Shared Source
* leaked materials
* private/non-public information
* Platform Builder
* undocumented/private Visual Studio implementation details
* illegally obtained material

---

## Windows CE Isolation

Windows CE is not desktop Windows.

Do not use W32/W64 or ordinary desktop Windows information as evidence for
Windows CE behavior.

Do not assume desktop Windows APIs, ABI, structures, constants, runtime
behavior, filesystem behavior, process behavior, synchronization behavior,
Unicode behavior, or CRT behavior apply to Windows CE.

Any Windows CE-specific behavior must be supported by Windows CE-specific
evidence when the distinction matters.

---

## Generation Isolation

Do not mix Windows CE generations without evidence.

For generation-sensitive APIs, structures, constants, libraries, ABI rules,
or behavior:

1. identify the generation;
2. verify documented availability;
3. identify differences;
4. record the evidence;
5. prevent accidental generation contamination.

Perform a dedicated generation-contamination review before completion.

---

## Legacy cellvm-sdk Comments

Comments describing obsolete conventions, plans, or requirements are
legacy information unless independently confirmed.

Do not follow obsolete comments.

When confirmed obsolete, remove or correct them so future agents do not
mistake them for active requirements.

---

## POSIX

Do not modify native Windows CE API definitions to emulate POSIX.

Where POSIX compatibility is required, implement it as a separate
compatibility layer in `cellvm-sdk`.

Conceptually:

POSIX API
→ cellvm-sdk compatibility layer
→ Windows CE API

Native Windows CE declarations must remain native Windows CE declarations.

---

## LLVM Runtime Policy

For:

* libc
* libc++
* libc++abi
* libunwind
* compiler-rt

prefer connecting functionality to APIs actually provided by Windows CE.

Do not silently substitute:

* desktop Windows implementations
* Linux implementations
* generic POSIX implementations

when Windows CE-specific behavior is required.

---

## Long-Running Work

This project is a long-running research and implementation task.

For substantial work, use an ExecPlan defined by `PLANS.md`.

`AGENTS.md` contains durable repository rules.

`PLANS.md` contains the current project roadmap, milestones, implementation
strategy, decisions, and acceptance criteria.

Maintain the plan as a living document.

Do not stop merely because the task is large, unfamiliar, or requires
multiple iterations.

When progress is possible, continue with the next useful action.

Do not repeatedly perform the same failed action without new information.

After repeated failure:

1. inspect the failure;
2. identify the cause or hypothesis;
3. obtain additional evidence;
4. choose a materially different approach;
5. test again.

---

## Research / Implementation Cycle

Use this cycle continuously:

Research
→ Cross-check
→ Compare with implementation
→ Identify gaps
→ Implement
→ Build/Test
→ Analyze
→ Research again
→ Correct
→ Re-test

Do not assume that the first successful build proves correctness.

After new evidence is collected, compare it against the current
implementation before continuing.

---

## Build and Test

Test progressively:

1. focused component
2. focused test
3. cross-component integration
4. Windows CE target build
5. runtime/library validation
6. broader regression validation
7. final evidence cross-check

At minimum investigate the required Windows CE integration of:

* Clang/LLVM target support
* libc
* libc++
* libc++abi where required
* libunwind where required
* compiler-rt where required
* SDK discovery
* include paths
* library paths
* runtime selection
* target/toolchain integration

A successful compiler invocation alone is insufficient.

---

## Cross-Repository Rule

Changes in one repository must trigger consideration of the other.

After changing `cellvm-sdk`, check:

* LLVM include assumptions
* runtime assumptions
* library assumptions
* build configuration

After changing `llvm-project`, check:

* required Windows CE APIs
* `cellvm-sdk` declarations
* required libraries
* documentation evidence

Do not treat the repositories as independent after integration begins.

---

## Git and Push

Preserve unrelated user changes.

Before and after significant work inspect:

* `git status`
* relevant diffs
* `git diff --check`

If pushing is required, use the environment's configured `GITHUB_PAT`
without exposing the credential.

Never print, log, commit, or store the PAT.

A push is never considered task completion.

After pushing:

1. verify the pushed state;
2. update relevant submodule references when required;
3. continue integration;
4. continue testing;
5. perform final review.

---

## Autonomous Execution

Do not ask for confirmation for routine implementation decisions.

Resolve ordinary ambiguity using:

1. explicit user requirements
2. authoritative Windows CE evidence
3. repository architecture
4. tests
5. secondary evidence
6. engineering judgment

Ask only when blocked by:

* missing information unavailable through permitted research;
* unavailable permissions/credentials;
* genuinely destructive or irreversible decisions;
* a materially ambiguous requirement that cannot be resolved safely.

Do not create unnecessary idle periods.

When a long-running build/test is executing, perform safe independent
research, inspection, or preparation rather than repeatedly polling it.

---

## Completion

`cellvm-sdk` completion is NOT project completion.

Do not stop at:

* headers compiling
* `cellvm-sdk` building
* one LLVM component building
* Clang starting
* one Windows CE generation working
* one architecture working
* a push succeeding
* a submodule update succeeding

Completion requires:

1. required `cellvm-sdk` coverage;
2. required `llvm-project` Windows CE integration;
3. cross-repository integration;
4. successful required Windows CE target builds;
5. relevant tests;
6. header-placement review;
7. generation-contamination review;
8. documentation/evidence cross-check;
9. final diff review;
10. no known applicable gaps or inconsistencies.

Report completion only after the full Definition of Done in `PLANS.md` has
been satisfied.

Collected documentation must be stored in:

`kagurasumusun/wince-docs-corpus`
