# Agentic AI System Steering Spec

This document distills the YouTube transcript into a practical operating specification for building and steering an agentic AI system that runs on a schedule, uses tools/APIs, maintains memory through files, and improves through repeated execution.

The original example is a scheduled AI trading agent, but the architecture generalizes to any long-running agentic workflow: research agents, monitoring agents, reporting agents, operations agents, portfolio/watchlist agents, experiment-management agents, or code-maintenance agents.

---

## 1. Core Idea

Build an agent that does not rely on persistent chat memory. Instead, every scheduled run follows a disciplined loop:

1. **Wake up from a scheduled trigger.**
2. **Read the project files that define memory, rules, strategy, state, and recent logs.**
3. **Perform the task for that run.**
4. **Use external APIs/tools when needed.**
5. **Write back structured updates to files.**
6. **Commit/persist those updates so the next run starts with accurate context.**
7. **Notify the human only when useful or required.**

The key design principle is:

> Files are the agent’s durable memory, discipline, operating manual, and audit trail.

A scheduled agent should be treated as mostly stateless at the start of every run. The way to make it behave consistently is to force it to read the right files before acting and update the right files before exiting.

---

## 2. System Goals

The agentic system should be designed to:

- Run on a reliable schedule.
- Use a structured repository as its operating environment.
- Maintain durable memory through markdown/JSON/log files.
- Separate secrets from the repository.
- Use external APIs through environment variables.
- Apply explicit guardrails before taking actions.
- Record all important decisions and outcomes.
- Support human review and iteration.
- Improve its skills, prompts, and memory files over time.
- Avoid uncontrolled autonomy, especially when money, production systems, or irreversible external actions are involved.

For trading-like systems, begin in **paper/simulation mode** and only enable live execution after extensive testing, monitoring, and explicit human approval.

---

## 3. Mental Model

### 3.1 Stateless Wake-Ups

Each routine starts fresh. Assume the model does **not** remember prior conversations or decisions unless they are written in the repository.

Therefore every routine prompt must include instructions like:

> Before doing anything, read the required memory, strategy, state, and log files. After completing the task, update the appropriate files so the next scheduled run has current context.

### 3.2 Context Is a Budget

Treat context window space like money.

Do not ask the agent to read every file on every run unless necessary. Instead:

- Keep stable operating instructions concise.
- Keep current state separate from long historical logs.
- Summarize old logs into periodic review files.
- Archive stale details.
- Prefer structured memory files over giant unstructured transcripts.
- Give each routine a clear list of files it must read and files it may read only if needed.

### 3.3 Memory Is Architecture

The agent’s quality depends less on a single clever prompt and more on the structure of its memory system.

Good memory files should answer:

- What is the agent trying to accomplish?
- What rules must never be violated?
- What is the current state?
- What happened recently?
- What lessons has the agent learned?
- What tools/APIs are available?
- What should be updated after each run?

---

## 4. Recommended Repository Structure

Use a Git-backed project repository so remote scheduled runs can clone the repo, execute, update files, and push changes back.

```text
agent-project/
├── CLAUDE.md                         # Primary agent identity + operating instructions
├── README.md                         # Human-facing overview
├── .gitignore                        # Must exclude local secrets and temporary files
│
├── memory/
│   ├── agent_profile.md              # Role, mission, principles, tone, decision style
│   ├── strategy.md                   # Strategy or workflow logic
│   ├── guardrails.md                 # Hard constraints and risk limits
│   ├── current_state.md              # Latest state snapshot
│   ├── lessons_learned.md            # Durable learnings from previous runs
│   ├── open_questions.md             # Issues requiring human decision
│   └── glossary.md                   # Domain-specific terms and definitions
│
├── logs/
│   ├── action_log.md                 # Chronological record of actions taken
│   ├── research_log.md               # Research findings and source summaries
│   ├── decision_log.md               # Why decisions were made
│   ├── error_log.md                  # Failures, API issues, unexpected behavior
│   └── notification_log.md           # Messages sent to the human
│
├── reviews/
│   ├── daily_review.md               # Daily summary and self-assessment
│   ├── weekly_review.md              # Weekly reflection and strategy updates
│   └── monthly_review.md             # Larger trend analysis
│
├── routines/
│   ├── pre_run.md                    # Prompt for early/preparation run
│   ├── main_run.md                   # Prompt for primary execution run
│   ├── midday_check.md               # Prompt for monitoring/check-in run
│   ├── closeout.md                   # Prompt for end-of-day closeout
│   └── weekly_review.md              # Prompt for weekly review
│
├── scripts/
│   ├── api_client.py                 # Optional API helper code
│   ├── notify.py                     # Optional notification helper
│   ├── validate_state.py             # Optional consistency checks
│   └── summarize_logs.py             # Optional log compression
│
├── skills/
│   ├── research_skill.md             # How to research consistently
│   ├── decision_skill.md             # How to make decisions
│   ├── execution_skill.md            # How to take external actions safely
│   ├── logging_skill.md              # How to write useful logs
│   └── review_skill.md               # How to reflect and improve
│
└── tests/
    ├── dry_run_checklist.md          # Manual/automated dry-run tests
    └── routine_test_results.md       # Results from scheduled-run tests
```

This structure can be simplified for small projects, but the separation between **instructions**, **memory**, **logs**, **routines**, **skills**, and **tests** is important.

---

## 5. Persistent Memory Files

### 5.1 `CLAUDE.md` or Primary Agent Instruction File

Purpose: Defines the agent’s identity, mission, operating principles, and global rules.

Should include:

- Agent name and role.
- Primary objective.
- Non-negotiable constraints.
- Required operating loop.
- File-reading policy.
- File-writing policy.
- Tool/API usage policy.
- Notification policy.
- Safety and escalation rules.

Example:

```md
# Agent Operating Instructions

You are an autonomous scheduled agent operating inside this repository.

Your job is to execute the scheduled routine safely and update durable memory files.

At the start of every run:
1. Read this file.
2. Read the routine prompt that triggered this run.
3. Read all required memory files listed in that routine.
4. Inspect current state before taking action.

At the end of every run:
1. Update relevant logs.
2. Update current state if anything changed.
3. Record important lessons or unresolved questions.
4. Commit and push changes if running remotely.
5. Send a notification only if the routine requires it or if human attention is needed.

Never expose secrets.
Never assume credentials are stored in files.
Use environment variables for API keys.
If a required credential is missing, stop safely and log the issue.
```

---

### 5.2 `memory/strategy.md`

Purpose: Captures the domain strategy.

For a trading use-case, this includes:

- Investment objective.
- Time horizon.
- Asset universe.
- Buy/sell criteria.
- Risk-management rules.
- Research sources.
- Position sizing.
- Exit logic.
- Review cadence.

For a general agent, this includes:

- Workflow objective.
- Decision criteria.
- Prioritization rules.
- Success metrics.
- Known failure modes.

---

### 5.3 `memory/guardrails.md`

Purpose: Defines hard limits.

Examples for a trading agent:

```md
# Guardrails

- Start in paper trading mode unless live mode is explicitly enabled.
- Never use options, margin, leverage, or crypto unless explicitly authorized.
- Do not allocate more than X% of portfolio to one position.
- Do not open more than N new positions per week.
- Do not trade if required market data or account data is unavailable.
- Do not trade on ambiguous or low-confidence reasoning.
- Do not trade solely because of model enthusiasm.
- If daily loss exceeds threshold, stop and notify the human.
- If API responses conflict with local state, stop and reconcile.
```

Examples for a non-trading agent:

```md
# Guardrails

- Do not delete production data.
- Do not send external messages without satisfying notification rules.
- Do not modify user-facing systems without explicit approval.
- Do not continue after repeated API failures.
- Escalate when confidence is low or the action is irreversible.
```

---

### 5.4 `memory/current_state.md`

Purpose: The latest compact snapshot.

Should be short and easy to read every run.

Include:

- Current status.
- Active tasks.
- Current holdings/resources/projects.
- Open risks.
- Last successful run.
- Last failed run.
- Pending human decisions.
- Any state needed by the next run.

---

### 5.5 Logs

Logs should be append-only when possible.

Each entry should include:

- Timestamp.
- Routine name.
- Inputs checked.
- Actions taken.
- Decisions made.
- Tools/APIs called.
- Result.
- Errors.
- Follow-ups.

Example:

```md
## 2026-04-25 15:00 — Closeout Routine

### Files read
- CLAUDE.md
- memory/current_state.md
- memory/strategy.md
- memory/guardrails.md
- logs/action_log.md

### Actions
- Checked account status.
- Reviewed open alerts.
- No external action taken.

### Decisions
- Held current state because no high-confidence trigger was present.

### Files updated
- logs/action_log.md
- memory/current_state.md

### Notification
- No notification sent.
```

---

## 6. Routine Design

The transcript proposes several scheduled routines, each with a different purpose. The general pattern is:

| Routine | Purpose | Typical Behavior | Notification Policy |
|---|---|---|---|
| Pre-run / pre-market | Research, prepare, identify candidates | Gather information, update plans, flag urgent issues | Notify only if urgent |
| Main execution / market open | Execute prepared actions | Validate state, act if criteria are met, log decisions | Notify if action taken |
| Midday check | Monitor risk and state | Check for issues, adjust if allowed, avoid overtrading | Notify if important |
| Closeout | End-of-day review | Summarize actions, update memory, prepare next run | Send summary |
| Weekly review | Reflect and improve | Evaluate performance, update lessons/strategy | Send full review |

For a non-trading system, map these to:

- **Preparation routine**
- **Execution routine**
- **Monitoring routine**
- **Closeout routine**
- **Periodic review routine**

---

## 7. Routine Prompt Template

Every routine prompt should be explicit and self-contained.

```md
# Routine: [ROUTINE_NAME]

You are running as a scheduled agent inside this repository.

## Mission for this run

[Describe the specific goal of this scheduled run.]

## Required startup procedure

Before taking any action:

1. Read `CLAUDE.md`.
2. Read this routine file.
3. Read:
   - `memory/agent_profile.md`
   - `memory/strategy.md`
   - `memory/guardrails.md`
   - `memory/current_state.md`
   - `memory/lessons_learned.md`
4. Read the most recent relevant log entries:
   - `logs/action_log.md`
   - `logs/decision_log.md`
   - `logs/error_log.md`
5. Verify required environment variables are available.
6. If required credentials are missing, stop safely, update `logs/error_log.md`, and notify the human if appropriate.

## API and secret policy

Use environment variables only. Do not look for API keys in `.env` files unless the runtime explicitly provides them and they are excluded from Git.

Expected environment variables:

- `BROKER_API_KEY`
- `BROKER_API_SECRET`
- `BROKER_API_BASE_URL`
- `RESEARCH_API_KEY`
- `NOTIFICATION_API_KEY`
- `NOTIFICATION_DESTINATION_ID`

Never print secrets in logs or notifications.

## Allowed actions

[Define what this routine is allowed to do.]

## Forbidden actions

[Define what this routine must not do.]

## Decision policy

Before taking an external action:

1. Check the relevant guardrails.
2. State the decision criteria.
3. Compare the current situation to the criteria.
4. If confidence is insufficient, do not act.
5. If the action is high-impact or irreversible, require human approval unless live autonomy is explicitly enabled.

## End-of-run procedure

Before exiting:

1. Update all relevant logs.
2. Update `memory/current_state.md`.
3. Add durable lessons to `memory/lessons_learned.md` only if they are likely to matter in future runs.
4. Add unresolved issues to `memory/open_questions.md`.
5. If running remotely, commit and push changes to the main branch.
6. Send a notification according to this routine’s notification policy.
```

---

## 8. Example Routine: Preparation / Pre-Market

```md
# Routine: Preparation

## Mission

Prepare for the next execution window by researching relevant developments, updating candidate actions, and identifying risks.

## Required files

Read:

- `CLAUDE.md`
- `memory/strategy.md`
- `memory/guardrails.md`
- `memory/current_state.md`
- `memory/lessons_learned.md`
- `logs/research_log.md`
- `logs/decision_log.md`

## Tasks

1. Summarize the current state.
2. Research new developments using the configured research API.
3. Identify candidate actions.
4. Check each candidate against the strategy and guardrails.
5. Do not execute external actions unless this routine explicitly allows it.
6. Update `logs/research_log.md`.
7. Update `memory/current_state.md` with any relevant preparation notes.
8. Notify the human only for urgent issues or if human approval is required.
```

---

## 9. Example Routine: Execution

```md
# Routine: Execution

## Mission

Execute only high-confidence actions that satisfy the strategy, current state, and guardrails.

## Required files

Read:

- `CLAUDE.md`
- `memory/strategy.md`
- `memory/guardrails.md`
- `memory/current_state.md`
- `memory/lessons_learned.md`
- `logs/research_log.md`
- `logs/decision_log.md`
- `logs/error_log.md`

## Tasks

1. Validate current state using the relevant API.
2. Reconcile API state with `memory/current_state.md`.
3. Review candidate actions from the preparation routine.
4. Reject candidates that violate guardrails.
5. For each allowed action:
   - State the rationale.
   - State the risk.
   - State the expected effect.
   - Execute only if confidence is high enough.
6. Log every action or non-action.
7. Update current state.
8. Notify the human if an external action was taken or if execution failed.
```

---

## 10. Example Routine: Monitoring

```md
# Routine: Monitoring

## Mission

Check for risk, drift, errors, or conditions that require adjustment.

## Tasks

1. Read current state and recent action logs.
2. Query relevant APIs for live/current status.
3. Compare reality against expected state.
4. If state has drifted, reconcile or escalate.
5. Apply only pre-authorized adjustments.
6. Do not invent new strategy during monitoring.
7. Update logs.
8. Notify the human only if action was taken, risk threshold was crossed, or intervention is needed.
```

---

## 11. Example Routine: Closeout

```md
# Routine: Closeout

## Mission

Summarize the day, update memory, and prepare the next run.

## Tasks

1. Read current state and all logs from today.
2. Summarize what happened.
3. Record actions taken and actions intentionally skipped.
4. Identify mistakes, surprises, and useful lessons.
5. Update `memory/current_state.md`.
6. Update `reviews/daily_review.md`.
7. Add durable lessons to `memory/lessons_learned.md`.
8. Send the human a concise end-of-day summary.
```

---

## 12. Example Routine: Weekly Review

```md
# Routine: Weekly Review

## Mission

Reflect on the week, evaluate performance, and improve the system.

## Tasks

1. Read all daily reviews from the week.
2. Read action, decision, research, and error logs.
3. Compare outcomes against goals.
4. Identify what worked.
5. Identify what failed.
6. Grade the agent’s performance.
7. Propose updates to:
   - `memory/strategy.md`
   - `memory/guardrails.md`
   - `skills/*.md`
   - routine prompts
8. Apply only safe, clearly justified updates.
9. Add larger unresolved issues to `memory/open_questions.md`.
10. Send a weekly review notification.
```

---

## 13. Skills

Skills are reusable procedural instructions that make behavior more consistent.

Recommended skills:

### 13.1 Research Skill

Defines:

- Which sources/APIs to use.
- How to summarize findings.
- How to distinguish news, opinion, filings, rumors, and data.
- How to cite or log sources.
- How to avoid overreacting to low-quality information.

### 13.2 Decision Skill

Defines:

- Required evidence before action.
- Confidence threshold.
- How to compare alternatives.
- How to reason under ambiguity.
- When to do nothing.

### 13.3 Execution Skill

Defines:

- How to call APIs.
- How to validate responses.
- How to handle failed requests.
- How to avoid duplicate actions.
- How to reconcile external state with local memory.

### 13.4 Logging Skill

Defines:

- Required log fields.
- What goes in each log file.
- How much detail to include.
- How to avoid bloating context.

### 13.5 Review Skill

Defines:

- How to evaluate performance.
- How to convert mistakes into durable lessons.
- How to avoid overfitting to one bad outcome.
- How to propose prompt/strategy improvements.

---

## 14. Secrets and Environment Variables

Never store live credentials in Git.

Use environment variables in the scheduled runtime.

Example variable names:

```text
RESEARCH_API_KEY=
NOTIFICATION_API_KEY=
NOTIFICATION_DESTINATION_ID=
BROKER_API_KEY=
BROKER_API_SECRET=
BROKER_API_BASE_URL=
PAPER_TRADING=true
LIVE_TRADING=false
```

Important rules:

- Variable names must match exactly between the runtime environment and the routine prompts.
- If the agent cannot find a required key, it must stop safely.
- Do not log secrets.
- Rotate credentials if they were pasted into chat, committed to Git, or exposed in a prompt.
- Use separate paper/sandbox and live credentials when possible.

---

## 15. Local vs Remote Routines

### Local Routine

Runs on the user’s machine.

Pros:

- Easier to debug.
- Can access local files directly.
- Good for early testing.

Cons:

- Does not run if the machine/app is closed.
- Persistence depends on local environment.

### Remote Routine

Runs in a cloud environment.

Pros:

- Can run while the user’s machine is off.
- Better for 24/7 scheduled operation.
- Cleaner deployment model.

Cons:

- Requires a GitHub repository or equivalent remote source.
- Must explicitly commit and push file updates.
- Must configure cloud environment variables.
- Must handle branch permissions correctly.

For remote routines, the agent must be instructed:

> After updating memory/log files, commit and push changes back to the main branch so future runs can read the updated state.

---

## 16. Deployment Checklist

### 16.1 Repository

- [ ] Create project folder.
- [ ] Add memory, logs, routines, skills, scripts, reviews, and tests folders.
- [ ] Add `.gitignore`.
- [ ] Ensure no secrets are committed.
- [ ] Push repository to GitHub or equivalent.

### 16.2 Environment

- [ ] Create cloud runtime environment.
- [ ] Add required API keys as environment variables.
- [ ] Confirm exact variable names.
- [ ] Enable network access if the agent must use APIs.
- [ ] Use paper/sandbox credentials first.
- [ ] Rotate credentials if exposed.

### 16.3 Routine Setup

- [ ] Create scheduled routines.
- [ ] Point each routine to the correct repository.
- [ ] Point each routine to the correct cloud environment.
- [ ] Use the correct model.
- [ ] Paste the corresponding routine prompt.
- [ ] Configure branch-push permissions if remote updates are needed.
- [ ] Confirm schedules use the intended timezone.

### 16.4 Testing

- [ ] Run each routine manually with “run now.”
- [ ] Confirm it reads the correct files.
- [ ] Confirm it finds environment variables.
- [ ] Confirm it can call APIs.
- [ ] Confirm it updates logs.
- [ ] Confirm it updates current state.
- [ ] Confirm it commits/pushes changes.
- [ ] Confirm notifications work.
- [ ] Inspect the conversation history after each test.
- [ ] Fix prompts, files, and variable names until runs are reliable.

---

## 17. Example Schedule

For a trading-style workflow:

```text
06:00 Monday-Friday  Preparation / pre-market research
08:30 Monday-Friday  Market-open execution
12:00 Monday-Friday  Midday monitoring
15:00 Monday-Friday  Closeout
16:00 Friday          Weekly review
```

Adapt this to the domain.

For a research-monitoring agent:

```text
08:00 Monday-Friday  Scan new sources
12:00 Monday-Friday  Check priority updates
17:00 Monday-Friday  Daily summary
16:00 Friday          Weekly synthesis
```

For a code-maintenance agent:

```text
09:00 Monday-Friday  Dependency/security scan
13:00 Monday-Friday  Issue triage
17:00 Monday-Friday  PR/repo summary
15:00 Friday          Weekly maintenance review
```

---

## 18. Human Notification Policy

The agent should not spam the human.

Use notifications for:

- External actions taken.
- Errors that require attention.
- Missing credentials.
- Risk thresholds crossed.
- Daily or weekly summaries.
- Human approval requests.
- Major state changes.

Avoid notifications for:

- Routine low-importance checks.
- No-op runs unless requested.
- Verbose research dumps.
- Internal scratch reasoning.

A good notification should include:

```md
## Agent Update — [Routine Name]

Status: [Success / Warning / Failed / Needs Approval]

Summary:
- [Key point 1]
- [Key point 2]
- [Key point 3]

Actions taken:
- [Action or “None”]

Needs human attention:
- [Yes/No + reason]

Files updated:
- [List]
```

---

## 19. Safety and Guardrail Principles

Agentic autonomy should be phased in.

### Phase 1: Advisory Mode

The agent researches, reasons, and recommends, but does not act.

### Phase 2: Paper/Sandbox Mode

The agent acts only in simulation or sandbox APIs.

### Phase 3: Limited Live Mode

The agent can take low-risk live actions within strict limits.

### Phase 4: Expanded Live Mode

Only after repeated successful runs, clear logs, and human confidence.

For any high-impact domain:

- Prefer human approval gates.
- Use small limits.
- Log everything.
- Make rollback plans.
- Stop on uncertainty.
- Stop on missing or conflicting data.
- Review every run early on.

---

## 20. Anti-Patterns to Avoid

Avoid:

- Putting API keys into prompts or committed files.
- Letting the agent act without reading state.
- Letting the agent update state without logging why.
- Letting each routine invent its own rules.
- Keeping all memory in one massive file.
- Using only chat history as memory.
- Running remote routines without pushing updated files.
- Over-notifying the human.
- Under-testing scheduled routines.
- Optimizing from one lucky or unlucky outcome.
- Assuming benchmark performance means real-world performance.
- Confusing “financial analysis ability” with day-trading skill.

---

## 21. Agent Self-Improvement Loop

The agent should improve through structured reflection, not random prompt drift.

At the end of each daily/weekly review, ask:

1. What did I do well?
2. What did I misunderstand?
3. What information was missing?
4. Which guardrail prevented a bad action?
5. Which guardrail was too weak?
6. Which memory file was stale?
7. Which routine prompt was ambiguous?
8. Which skill should be updated?
9. What should I do differently next time?

Only update long-term memory when the lesson is durable.

---

## 22. Minimal First Version

If building from scratch, start with a minimal version:

```text
agent-project/
├── CLAUDE.md
├── memory/
│   ├── strategy.md
│   ├── guardrails.md
│   └── current_state.md
├── logs/
│   ├── action_log.md
│   └── error_log.md
└── routines/
    ├── daily_run.md
    └── weekly_review.md
```

Start with:

- One daily routine.
- One weekly review.
- No live irreversible actions.
- Human review of every run.
- Paper/sandbox API mode.

Then expand only after the system is reliable.

---

## 23. One-Shot Bootstrap Prompt

Use this prompt to create a new agentic routine project:

```md
I want to create a scheduled agentic AI system inside this repository.

Your job is to help me design the project structure, memory architecture, routine prompts, guardrails, and testing process.

Assume each scheduled run starts mostly stateless. The agent must read durable memory files at the beginning of each run and write updated memory/log files at the end.

Please propose:
1. A repository structure.
2. The minimum memory files needed.
3. The routine prompts needed.
4. The guardrails.
5. The environment variables.
6. The logging format.
7. A dry-run test plan.
8. A deployment checklist.

Do not assume secrets are stored in the repository. All API keys must come from environment variables.

Do not design the system for uncontrolled autonomy. Start with advisory or sandbox mode, then propose a phased path toward more autonomy only after testing.
```

---

## 24. Migration Prompt From an Existing Agent

Use this if moving from an existing agent/chat/system:

```md
I am migrating an existing agentic workflow into this repository.

I will provide strategy notes, old logs, prior decisions, current state, and lessons learned.

Your task:
1. Ingest the supplied context.
2. Identify durable knowledge worth preserving.
3. Separate strategy, guardrails, current state, logs, and lessons.
4. Create or update the repository memory files.
5. Create scheduled routine prompts that read the correct files before acting.
6. Ensure all API credentials are referenced only through environment variables.
7. Add a dry-run checklist.
8. Do not enable live irreversible actions by default.

Before making changes, produce a plan and ask clarifying questions only if needed.
```

---

## 25. Final Operating Contract

A well-steered scheduled agent should obey this contract:

```md
At the start of every run, I read my instructions, state, strategy, guardrails, and relevant logs.

Before acting, I verify external state through APIs and compare it to local memory.

I only act when the action is allowed, justified, and within guardrails.

I log what I did, why I did it, and what happened.

I update durable memory so the next run is smarter and better informed.

I never store or reveal secrets.

I stop safely when required information is missing, contradictory, or too uncertain.

I notify the human when action, risk, failure, or approval requires attention.
```
