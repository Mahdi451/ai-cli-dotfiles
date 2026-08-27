# AI CLI dotfiles

Portable Linux/WSL configuration for opinionated Cursor and Codex CLI workflows: guarded launchers, model hierarchies, reusable agent roles, shell aliases, validation rules, and safe install/backup tooling.

> **Core idea:** keep routine work with the cheapest capable owner, use deterministic validation early, and spend expensive reasoning only when it materially improves the probability of success.

## At a glance

| Workflow | Primary command | Normal/safe command | Default owner | Senior reasoning | Use case |
| --- | --- | --- | --- | --- | --- |
| **GPT Hierarchy v2** | `cyolo` | `codex-st` | Terra Medium | Sol High / Sol Max | Home Codex workflow |
| **Groky** | `groky` | `groky-safe` | Composer 2.5 | Grok 4.6 High / xHigh | Token-conscious Cursor workflow |
| **Original Cursor** | `cursory` | `cagent` | Sol High | Sol Max | Legacy Sol/Terra/Luna Cursor workflow |

### Launcher map

```mermaid
flowchart LR
    U([You])

    U -->|Home GPT| CYOLO[cyolo]
    U -->|Home GPT, normal approvals| CST[codex-st]
    U -->|Work Cursor, autonomous| GROKY[groky]
    U -->|Work Cursor, normal approvals| GSAFE[groky-safe]
    U -->|Original Cursor, autonomous| CURSORY[cursory]
    U -->|Original Cursor, normal approvals| CAGENT[cagent]

    CYOLO --> CODEX[GPT Hierarchy v2]
    CST --> CODEX
    GROKY --> CG[Composer + Grok]
    GSAFE --> CG
    CURSORY --> STL[Sol / Terra / Luna]
    CAGENT --> STL

    classDef user fill:#111827,stroke:#64748b,color:#f8fafc,stroke-width:2px;
    classDef gpt fill:#172554,stroke:#60a5fa,color:#eff6ff,stroke-width:2px;
    classDef grok fill:#052e16,stroke:#4ade80,color:#f0fdf4,stroke-width:2px;
    classDef cursor fill:#3f1d0b,stroke:#fb923c,color:#fff7ed,stroke-width:2px;
    class U user;
    class CYOLO,CST,CODEX gpt;
    class GROKY,GSAFE,CG grok;
    class CURSORY,CAGENT,STL cursor;
```

## Which launcher should I use?

```mermaid
flowchart TD
    START([Start a coding task]) --> WHERE{Which environment?}

    WHERE -->|Home / Codex| GPTRISK{Want full approvals?}
    WHERE -->|Work / Cursor| CURSORSTYLE{Which hierarchy?}

    GPTRISK -->|Yes| CYOLO[cyolo]
    GPTRISK -->|No| CST[codex-st]

    CURSORSTYLE -->|Composer + Grok| GROKAPP{Approval mode?}
    CURSORSTYLE -->|Original Sol / Terra / Luna| OLDAPP{Approval mode?}

    GROKAPP -->|Normal| GSAFE[groky-safe]
    GROKAPP -->|Autonomous| GROKY[groky]

    OLDAPP -->|Normal| CAGENT[cagent]
    OLDAPP -->|Autonomous| CURSORY[cursory]

    classDef decision fill:#0f172a,stroke:#94a3b8,color:#f8fafc;
    classDef safe fill:#0c4a6e,stroke:#38bdf8,color:#f0f9ff;
    classDef auto fill:#3f1d0b,stroke:#fb923c,color:#fff7ed;
    class WHERE,GPTRISK,CURSORSTYLE,GROKAPP,OLDAPP decision;
    class CST,GSAFE,CAGENT safe;
    class CYOLO,GROKY,CURSORY auto;
```

---

# GPT Hierarchy v2 — home Codex workflow

The optimized home hierarchy is Terra-led. Routine tasks stay in one Terra context; Luna is opportunistic; Sol High is conditional; Sol Max is exceptional.

### Architecture

```mermaid
flowchart TD
    T[Terra Medium<br/>Primary Task Owner]
    L[Luna Medium<br/>Bounded Cheap Support]
    V[Tests / Typecheck / Lint / Build<br/>Deterministic Validation]
    SA[Sol High<br/>Architect]
    SR[Sol High<br/>Independent Reviewer]
    SM[Sol Max<br/>Exceptional Escalation]
    FIX[Terra<br/>Fix Findings]
    DONE([Done])

    T -->|Routine work| V
    V -->|Routine + passing| DONE

    T -->|Large mechanical / bounded task| L
    L -->|Handoff| T

    T -->|Architecture / security / persistence / concurrency| SA
    SA -->|Acceptance criteria + approach| T

    V -->|Consequential change| SR
    SR -->|No material findings| DONE
    SR -->|Actionable findings| FIX
    FIX --> V

    T -->|Credible attempts still blocked| SR
    SR -->|Still materially uncertain| SM
    SM -->|Diagnosis / recommendation| T

    classDef owner fill:#172554,stroke:#60a5fa,color:#eff6ff,stroke-width:2px;
    classDef cheap fill:#164e63,stroke:#22d3ee,color:#ecfeff;
    classDef senior fill:#3b0764,stroke:#c084fc,color:#faf5ff,stroke-width:2px;
    classDef verify fill:#1f2937,stroke:#94a3b8,color:#f8fafc;
    classDef done fill:#052e16,stroke:#4ade80,color:#f0fdf4,stroke-width:2px;
    class T,FIX owner;
    class L cheap;
    class SA,SR,SM senior;
    class V verify;
    class DONE done;
```

### Routing contract

```text
Routine:
  Terra -> validate -> diff inspection -> done

Bounded cheap support:
  Terra -> Luna -> Terra verifies/integrates -> validate -> done

Important:
  Terra -> validate -> Sol High reviewer -> Terra fixes -> validate -> done

Architectural:
  Sol High architect -> Terra implements -> validate -> Sol High reviewer -> done

Exceptional:
  Terra attempts -> Sol High diagnosis -> Sol Max only if material uncertainty remains
```

| Role | Model + effort | Responsibility |
| --- | --- | --- |
| Terra parent | `gpt-5.6-terra` + medium | Default owner: inspect, implement, test, debug, integrate, self-review |
| Luna worker | `gpt-5.6-luna` + medium | Optional isolated low-risk/mechanical support |
| Terra reviewer | `gpt-5.6-terra` + high | Optional routine second pass, mainly for Luna work |
| Sol architect | `gpt-5.6-sol` + high | Architecture and acceptance criteria for consequential changes |
| Sol reviewer | `gpt-5.6-sol` + high | Independent integrated-diff review |
| Sol Max advisor | `gpt-5.6-sol` + max | Exceptional escalation only |

### Commands

```bash
# Normal Codex approvals / sandbox
codex-st "Implement the requested change and validate it."

# Canonical full-approval home GPT alias
cyolo "Implement the reviewed change and validate it."
```

`cyolo` expands to:

```bash
codex-st --dangerously-bypass-approvals-and-sandbox
```

`codexy` remains only as a backward-compatible alias for the same command.

See [`codex/HIERARCHY.md`](codex/HIERARCHY.md) and [`codex/prompts/terra-led-workflow.md`](codex/prompts/terra-led-workflow.md).

---

# Groky — Composer 2.5 + Grok 4.6 Cursor workflow

Groky is the token-conscious work hierarchy: Composer owns normal coding, tests, debugging, and integration; Grok enters only when deeper reasoning or independent review is worth the extra context and cost.

### Architecture

```mermaid
flowchart TD
    C[Composer 2.5<br/>Primary Task Owner<br/>fast=false]
    V[Tests / Typecheck / Lint / Build<br/>Deterministic Validation]
    GM[Grok 4.6 Medium<br/>Targeted Advisor<br/>fast=false]
    GH1[Grok 4.6 High<br/>Architect<br/>fast=false]
    GH2[Grok 4.6 High<br/>Reviewer<br/>fast=false]
    GX[Grok 4.6 xHigh<br/>Exceptional Escalation<br/>fast=false]
    FIX[Composer<br/>Fix Findings]
    DONE([Done])

    C -->|Routine| V
    V -->|Routine + passing| DONE

    C -->|Stubborn debugging| GM
    GM -->|Focused recommendation| C

    C -->|Architecture / high-risk design| GH1
    GH1 -->|Acceptance criteria + approach| C

    V -->|Important / high-risk| GH2
    GH2 -->|No material findings| DONE
    GH2 -->|Actionable findings| FIX
    FIX --> V

    GH2 -->|Still materially uncertain| GX
    GX -->|Diagnosis / recommendation| C

    classDef owner fill:#052e16,stroke:#4ade80,color:#f0fdf4,stroke-width:2px;
    classDef grok fill:#3b0764,stroke:#c084fc,color:#faf5ff,stroke-width:2px;
    classDef verify fill:#1f2937,stroke:#94a3b8,color:#f8fafc;
    classDef done fill:#172554,stroke:#60a5fa,color:#eff6ff,stroke-width:2px;
    class C,FIX owner;
    class GM,GH1,GH2,GX grok;
    class V verify;
    class DONE done;
```

### Routing contract

```text
Routine:
  Composer -> validate -> diff inspection -> done

Stalled:
  Composer -> Grok Medium advisor -> Composer -> validate

Important:
  Composer -> validate -> Grok High reviewer -> Composer fixes -> validate -> done

Architectural:
  Grok High architect -> Composer -> validate -> Grok High reviewer -> done

Exceptional:
  Grok xHigh only after credible Composer + Grok High attempts
```

### Fast mode policy: always off

Every managed Cursor model is explicitly non-Fast.

| Role | Model |
| --- | --- |
| Composer parent | `composer-2.5` + `fast=false` |
| Composer delegate | `composer-2.5[fast=false]` |
| Grok advisor | `grok-4.6[effort=medium,fast=false]` |
| Grok architect | `grok-4.6[effort=high,fast=false]` |
| Grok reviewer | `grok-4.6[effort=high,fast=false]` |
| Grok escalation | `grok-4.6[effort=xhigh,fast=false]` |

`cursor-st --groky` launches with `--model composer-2.5[fast=false]` so the CLI cannot fall back to Auto / Auto Balance. It also rewrites the selected Composer parent to non-Fast in `cli-config.json` before startup. Custom agents carry independent `fast=false` pins, and the doctor rejects managed custom agents missing the explicit pin. Built-in/automatic subagents are not part of the managed Groky path when their speed variant cannot be verified.

### Commands

```bash
# Normal Cursor approval behavior
groky-safe "Implement the requested change and validate it."

# Full-autonomy work workflow
groky "Implement the reviewed change and validate it."
```

See [`cursor/GROKY.md`](cursor/GROKY.md) and [`cursor/prompts/groky-workflow.md`](cursor/prompts/groky-workflow.md).

---

# Original Cursor — Sol / Terra / Luna

The original managed Cursor hierarchy remains available for compatibility.

```mermaid
flowchart LR
    S[Sol High<br/>Parent<br/>fast=false] --> T[Terra Medium<br/>Implementation<br/>fast=false]
    T --> L[Luna Medium<br/>Bounded Support<br/>fast=false]
    L --> T
    T --> R[Terra High<br/>Routine Review<br/>fast=false]
    R --> S
    S -. exceptional .-> SM[Sol Max<br/>fast=false]

    classDef lead fill:#172554,stroke:#60a5fa,color:#eff6ff,stroke-width:2px;
    classDef worker fill:#164e63,stroke:#22d3ee,color:#ecfeff;
    classDef senior fill:#3b0764,stroke:#c084fc,color:#faf5ff;
    class S lead;
    class T,L,R worker;
    class SM senior;
```

```bash
cagent     # normal approvals
cursory    # cursor-st --yolo
```

All managed models in this Cursor hierarchy are also pinned to `fast=false`.

---

## Command matrix

| Command | CLI | Hierarchy | Approval behavior | Recommended use |
| --- | --- | --- | --- | --- |
| `cyolo` | Codex | GPT Hierarchy v2 | Full bypass | Home trusted/sandboxed execution |
| `codex-st` | Codex | GPT Hierarchy v2 | Normal | Home standard use |
| `groky` | Cursor | Composer + Grok | `--yolo` | Work trusted autonomous execution |
| `groky-safe` | Cursor | Composer + Grok | Normal | Work standard use |
| `cursory` | Cursor | Sol/Terra/Luna | `--yolo` | Legacy Cursor autonomous mode |
| `cagent` | Cursor | Sol/Terra/Luna | Normal | Legacy Cursor standard mode |
| `codexy` | Codex | GPT Hierarchy v2 | Full bypass | Compatibility alias for `cyolo` |
| `cdx` | Codex | Raw Codex | Native | Intentionally bypass managed hierarchy |

## Installation

Prerequisites: Linux or WSL, Bash, Python 3.11+, Git, `rg`, and the official Cursor and/or Codex CLI already installed and authenticated.

```bash
git clone git@github.com:YOUR-ACCOUNT/ai-cli-dotfiles.git
cd ai-cli-dotfiles

./doctor.sh --repo-only
./tests/smoke-test.sh
git diff --check

./install.sh --dry-run
./install.sh
source ~/.bashrc
./doctor.sh
```

Useful install options:

| Option | Effect |
| --- | --- |
| `--copy` | Install independent copies instead of symlinks |
| `--cursor-only` | Install Cursor assets and shared aliases only |
| `--codex-only` | Install Codex assets and shared aliases only |
| `--replace-config` | Back up and replace the Codex base config template |
| `--force` | Replace a protected changed/unrecognized target after backup |
| `--full-access` | Store Cursor unrestricted approval/disabled sandbox preferences |

## Inspect the active workflows

```bash
# Original Cursor
cursor-st --show-flow
cursor-st --doctor

# Groky
cursor-st --groky --show-flow
cursor-st --groky --doctor

# GPT Hierarchy v2
codex-st --show-flow
codex-st --doctor

# Alias helper
cdoctor
```

## Installed mappings

| Repository source | Destination |
| --- | --- |
| `cursor/agents/*.md` | `~/.cursor/agents/` |
| `cursor/rules/*.mdc` | `~/.cursor/rules/` |
| `cursor/hooks.json` | merged into `~/.cursor/hooks.json` |
| `cursor/cli-config.json` | selected portable fields merged into `~/.cursor/cli-config.json` |
| `bin/cursor-st` | `~/.local/bin/cursor-st` |
| `codex/AGENTS.md` | `~/.codex/AGENTS.md` |
| `codex/rules/default.rules` | `~/.codex/rules/default.rules` |
| `codex/config/sol-terra-luna.config.toml` | `~/.codex/sol-terra-luna.config.toml` |
| `codex/agents/*.toml` | `~/.codex/agents/` |
| `codex/config/config.toml` | `~/.codex/config.toml` only if missing or explicitly replaced |
| `bin/codex-st` | `~/.local/bin/codex-st` |
| `shell/ai-cli-aliases.sh` | `${XDG_CONFIG_HOME:-$HOME/.config}/ai-cli-dotfiles/ai-cli-aliases.sh` |

`CURSOR_HOME`, `CODEX_HOME`, `XDG_STATE_HOME`, and `XDG_CONFIG_HOME` are honored where applicable.

## Maintenance and recovery

```bash
./doctor.sh --repo-only
./tests/smoke-test.sh
git diff --check

./backup-current.sh
./backup-current.sh --include-codex

./uninstall.sh --dry-run
./uninstall.sh --restore
```

The backup workflow preserves Cursor's selected-model `fast=false` parameter.

## Security

Never commit credentials, authentication JSON, private keys, `.env` files, sessions, logs, model history, local databases, machine trust entries, or other secrets.

The repository scanner is a guardrail, not permission to commit sensitive material. High-autonomy aliases (`cyolo`, `groky`, `cursory`) should only be used in trusted or appropriately sandboxed environments.

Repository validation proves the portable configuration is internally consistent; it does not prove account access, model availability, or that unrestricted execution is safe in a particular project.
