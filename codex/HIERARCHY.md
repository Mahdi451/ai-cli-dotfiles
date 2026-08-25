# GPT Hierarchy v2

The home Codex workflow is optimized around one principle: use the cheapest capable model to own the work, then spend stronger reasoning only where it materially improves correctness.

## Roles

| Role | Model | Responsibility |
| --- | --- | --- |
| Terra parent | GPT-5.6 Terra, medium | Default task owner: inspect, plan normal work, implement, test, debug, integrate, self-review, finish |
| Luna worker | GPT-5.6 Luna, medium | Optional bounded low-risk support only |
| Terra reviewer | GPT-5.6 Terra, high | Optional read-only second pass, mainly for delegated Luna work |
| Sol architect | GPT-5.6 Sol, high | Read-only architecture/acceptance criteria for consequential design changes |
| Sol reviewer | GPT-5.6 Sol, high | Read-only independent review for important/high-risk integrated changes |
| Sol Max advisor | GPT-5.6 Sol, max | Exceptional read-only escalation after Terra + Sol High remain uncertain |

## Canonical routing

### Routine

```text
Terra
  -> inspect relevant code
  -> implement
  -> tests / typecheck / lint / build / runtime validation as appropriate
  -> inspect diff
  -> done
```

No Sol call is required.

### Bounded cheap support

```text
Terra
  -> Luna: isolated, explicit, low-risk subtask
  -> Terra verifies and integrates
  -> deterministic validation
  -> done
```

Use Luna only when the delegation and verification cost is lower than Terra simply doing the work.

### Important

```text
Terra
  -> implement
  -> deterministic validation
  -> compact handoff
  -> Sol High review
  -> Terra fixes valid findings
  -> deterministic validation
  -> done
```

### Architecturally significant

```text
Terra gathers minimum relevant context
  -> Sol High architecture + acceptance criteria
  -> Terra implements
  -> deterministic validation
  -> Sol High integrated review
  -> Terra fixes valid findings
  -> validation
  -> done
```

### Stalled / exceptional

```text
Terra makes credible attempts
  -> Sol High targeted diagnosis
  -> Terra implements recommendation
  -> validate
  -> still materially uncertain?
       -> Sol Max advisory escalation
       -> Terra implements
       -> validate
```

Do not jump directly to Sol Max.

## Compact handoff contract

Before escalating, provide only what the next agent needs:

- Objective
- Acceptance criteria
- Relevant architecture
- Relevant/changed files
- Important implementation decisions
- Validation already run and results
- Observed failure or uncertainty
- Current git diff

The receiving agent should start from this handoff and expand repository exploration only when a concrete concern requires it.

## Review policy

Deterministic validation comes before expensive model review whenever practical. Sol review is conditional, not ceremonial. Routine work can complete on Terra after successful validation and diff inspection.

For consequential work, the implementation model should not be the only source of validation: use deterministic checks first and Sol High independent review second.

## Delegation admission rule

Delegate to Luna only when all are true:

1. The task is bounded.
2. Risk is low.
3. Acceptance criteria are explicit.
4. Output is cheap to verify.
5. The handoff is short enough that delegation is actually cheaper.

Otherwise Terra keeps ownership.

## Completion

A task is complete when the requested behavior exists, relevant verification passes, the diff has been inspected, required senior-review findings are handled, and remaining limitations are stated honestly.

The hierarchy is an ownership and escalation system, not a ranking of model intelligence and not a quota system.