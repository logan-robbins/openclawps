---
name: deep_research
description: Rigorous web research with progress tracking, evidence checks, and context control.
---

# Deep Research

Use this skill for substantial research tasks that need multiple sources, careful verification, current information, or synthesized analysis.

Examples:
- deep dives on companies, products, policies, markets, frameworks, or current events
- literature reviews or topic overviews that need multiple sources
- comparative research across vendors, tools, standards, or public claims
- questions where the user explicitly wants “deep research”, “research X in depth”, or a structured report

Do not use this skill for trivial single-fact lookups, simple URL fetches, or quick summaries that can be answered with one or two lightweight tool calls.

## OpenClaw operating boundaries

- Treat this skill as behavior guidance inside a normal OpenClaw run. It does **not** create durable workflow state by itself.
- If the task must survive restarts, run in the background with tracked progress, or continue as a true multi-step workflow, use the runtime’s actual orchestration features when they are available (for example Task Flow, background tasks, cron, heartbeat, or sub-agents).
- Do not claim that the skill itself provides restart-safe progress tracking.
- Keep the frontmatter description short. The description is injected into the system prompt; the body is read on demand.

## Tool preference

When the Bright Data OpenClaw plugin is available, prefer its tools for web work:
- `brightdata_search`
- `brightdata_search_batch`
- `brightdata_scrape`
- `brightdata_scrape_batch`
- `brightdata_browser_navigate`
- `brightdata_browser_snapshot`
- `brightdata_browser_click`
- `brightdata_browser_type`
- `brightdata_browser_fill_form`
- `brightdata_browser_screenshot`
- `brightdata_browser_get_html`
- `brightdata_browser_get_text`
- `brightdata_browser_scroll`
- `brightdata_browser_scroll_to`
- `brightdata_browser_wait_for`
- `brightdata_browser_network_requests`
- `brightdata_browser_go_back`
- `brightdata_browser_go_forward`
- relevant platform-specific `brightdata_*` structured extractors

Use browser automation only when search or scrape is insufficient.
- Prefer `brightdata_search` / `brightdata_search_batch` for discovery.
- Prefer `brightdata_scrape` / `brightdata_scrape_batch` for reading pages.
- Use browser tools only for interactive pages, lazy-loaded content, login-free click paths, screenshots, or evidence that cannot be captured reliably by scrape.
- Use structured extractors when the target platform already has a typed Bright Data tool.

If Bright Data is unavailable, use the web tools that are actually exposed by the current OpenClaw runtime rather than stalling.

## Progress tracking discipline

For any research task larger than a quick lookup, maintain a compact research state and update it as work progresses.

Use this structure:

```markdown
Research State
- Objective:
- Success condition:
- Sub-questions:
  1.
  2.
  3.
- Current branch:
- Done:
- Remaining gaps:
- Sources locked:
- Next actions:
```

Rules:
- Update the state after each major search or extraction cycle.
- Keep at most 3 active unresolved branches at once.
- Collapse completed branches into one short line each.
- Surface meaningful progress to the user during long jobs instead of disappearing into tool loops.
- If evidence is weak or conflicting, say so early.

If file-editing tools are available and the task is large, keep the research state in a temporary workspace note so it can be reread without replaying every raw tool result. Otherwise keep the state compact in the running conversation.

## Planning rules

Before deep research begins:
1. Restate the objective in one sentence.
2. Define a stop condition.
3. Break the topic into 3-5 sub-questions.
4. Identify which parts are freshness-sensitive or likely to need primary sources.
5. Decide whether any branches are truly independent enough for parallel work.

Use no more decomposition than necessary. Over-planning wastes context.

## Research workflow

### 1) Scope and source strategy
Choose the likely best source classes before searching:
- official docs, standards, government pages, company pages, or primary datasets for authoritative claims
- reputable news or trade press for recent developments
- secondary explainers only when they add synthesis or accessibility

For volatile topics, explicitly capture dates.

### 2) Breadth-first search
Start with a broad discovery pass.
- Generate 3-6 deliberate queries, not a huge query dump.
- Mix broad, narrow, and source-targeted queries.
- Use batch search when possible.
- Dedupe quickly by domain and likely claim coverage.
- Build a candidate list of roughly 5-8 URLs maximum before opening pages.

Do **not** keep raw search results in working context longer than needed.

### 3) Focused extraction
Read the most promising sources first.
- Open 3-6 sources, not everything.
- Prefer primary sources before commentary when possible.
- For each opened page, immediately compress it into a short evidence note:

```markdown
Source Note
- Source:
- Why it matters:
- Key facts:
  -
  -
  -
- Trust level: primary / official / secondary / weak
- Open questions:
```

Once the note is captured, stop carrying the raw page output unless it is still actively needed.

### 4) Verification pass
For each material claim:
- prefer one primary or official source
- add at least one independent corroborating source when the claim is important
- add a third source when the claim is disputed, high-stakes, surprising, or very recent
- if sources disagree, report the disagreement explicitly instead of forcing a false consensus

Do not fetch extra pages just to satisfy a source-count ritual when the primary evidence is already clear.

### 5) Gap-closing pass
Only run another search cycle if there is a concrete unanswered question.
Good reasons for another cycle:
- a key claim still lacks corroboration
- the best source is outdated
- the current evidence conflicts
- a crucial metric, date, or quote is still missing

Bad reasons:
- curiosity without impact on the answer
- repeating nearly identical queries
- opening multiple pages that all restate the same fact

## Context and noise control

This is mandatory.

- Keep only the current research state, the active evidence notes, and the final synthesis outline in working context.
- Do not keep raw SERP dumps after choosing candidate URLs.
- Do not open near-duplicate pages from the same site unless they fill a specific gap.
- Keep at most 5 active evidence pages in working context at once.
- Prefer smaller, bounded extractions when the tool supports limits.
- Summarize large outputs immediately.
- If 2 consecutive source fetches add no material evidence, stop and either synthesize or pivot.
- Never repeat the exact same tool call unless inputs changed or there is a documented retry reason.
- Retry a failing page at most 2 times.
- Prefer scrape over browser, and search over browser, unless interaction is required.

## Parallel work and sub-agents

Only parallelize when the topic naturally splits into independent branches.

If OpenClaw session tools are available and parallel work would actually help:
- use `sessions_spawn` for a small number of narrow branches
- keep each child narrowly scoped with a fixed return shape:

```markdown
Child Return
- Branch:
- Answer:
- Evidence:
- Sources:
- Confidence:
- Remaining gaps:
```

Rules for spawned work:
- Spawn only 2-4 branches unless the task clearly needs more.
- Do not create child branches for trivial lookups.
- Do not poll `sessions_list`, `sessions_history`, or `/subagents list` in waiting loops.
- Use `sessions_yield` when the best next step is to end the turn and wait for child results.
- Otherwise continue independent work in the main session and merge child results when they arrive.
- If a child finishes after the final answer was already delivered, handle that follow-up according to runtime policy instead of narrating stale progress.

## Checklist-style recurring research

Do not turn this skill into a fake scheduler.

If the user wants recurring scans or periodic monitoring:
- use heartbeat for small checklist-style periodic awareness
- use a `HEARTBEAT.md` checklist or `tasks:` block for due-only periodic checks
- use cron for exact timing
- use Task Flow when durable multi-step orchestration is needed
- use standing orders in `AGENTS.md` for persistent authority, triggers, approval gates, and escalation rules

## User-facing behavior

For substantial jobs, show a brief plan before the deepest tool work begins.
Then provide short progress updates that reflect the actual research state:
- what is done
- what remains uncertain
- what the next evidence-gathering step is

Do not drown the user in operational chatter.

## Output format

When the user asked for deep research or the work was substantial, return a structured report.

Use this shape unless the user asked for a different format:

# Research Report: [Topic]
**Date:** [current date]
**Question:** [user’s query]
**Method:** [brief summary of search/extraction/verification approach]

## Executive Summary
2-4 sentences.

## Key Findings
- concise findings with citations

## Detailed Analysis
Use subsections that match the research questions.

## Conflicts, Gaps, and Confidence
State what is well-supported, what is uncertain, and why.

## Sources
List the most important sources with short labels.

## Method notes
Include meaningful research details only: search breadth, whether Bright Data tools were used, whether browser interaction was necessary, and whether any evidence remained unavailable.

## Research quality bar

A strong answer should:
- answer the user’s actual question, not just summarize pages
- distinguish primary evidence from commentary
- capture dates for volatile claims
- surface uncertainty honestly
- avoid needless tool spam
- leave a compact evidence trail that can be continued later without replaying the whole transcript

## Safety and policy

- Never invent a source, quote, or statistic.
- Do not use Bright Data for unsupported account-management use cases.
- Respect site restrictions and applicable platform policies.
- If the evidence is thin, say so.
- If the best answer is “not enough reliable information,” say that directly.
