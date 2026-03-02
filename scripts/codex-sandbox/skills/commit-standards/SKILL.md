---
name: commit-standards
description: Write token-efficient git commit messages with concise but complete bodies, including what changed, why, assumptions, alternatives, history, and issue-fix validation details.
---

# Commit Standards

Use this skill when drafting, revising, or reviewing commit messages.

## Goals

- Be terse. Every line must earn its tokens.
- Optimize for both human and agent readers.
- Keep claims factual and specific.

## Required Body Content

Commit message bodies must include:

- Detailed description of changes made.
- Why this approach was taken.
- Assumptions made.

## Recommended Body Content

Include when relevant:

- Alternatives considered and why they were not chosen.
- Relevant history and context.
- Original prompt or request summary.
- Approaches abandoned and why.

## If The Commit Solves An Issue

Also include:

- Detailed problem description.
- Assumptions made while diagnosing/fixing.
- Reproduction steps (if known and relevant).
- Validation steps and evidence that resolution worked.

## Style

- Use short sections with clear labels.
- Prefer concrete nouns, filenames, commands, and outcomes.
- Avoid filler, repetition, and long prose.
- Keep scope aligned with the diff.

## Suggested Body Template

```text
Changes:
- ...

Why:
- ...

Assumptions:
- ...

Alternatives considered:
- ...

Context/history:
- ...

Abandoned approaches:
- ...
```

## Suggested Issue-Fix Addendum

```text
Problem:
- ...

Reproduction:
- ...

Validation:
- ...
```
