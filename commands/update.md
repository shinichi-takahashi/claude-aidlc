---
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - AskUserQuestion
description: "Update AI-DLC workflow rules to the latest version"
argument-hint: "[--force]"
---

# /aidlc:update — Update AI-DLC Workflow Rules

You are updating the AI-DLC (AI-Driven Development Life Cycle) workflow rules to the latest version from [awslabs/aidlc-workflows](https://github.com/awslabs/aidlc-workflows).

## Steps

### 0. Locate Plugin Script

Use the Glob tool to find `fetch-aidlc.sh`. Search in this order (first match wins):

1. **Project root** (current working directory):
```
pattern: "**/.claude-plugin/../scripts/fetch-aidlc.sh"
path: "."
```
or more directly:
```
pattern: "**/claude-aidlc/scripts/fetch-aidlc.sh"
path: ".claude"
```

2. **User root** (fallback):
```
pattern: "**/claude-aidlc/scripts/fetch-aidlc.sh"
path: "~/.claude"
```

3. If still not found, also try broader patterns:
```
pattern: "**/aidlc/scripts/fetch-aidlc.sh"
```
in both `.claude` and `~/.claude`.

Store the resolved absolute path as `FETCH_SCRIPT` for use in later steps. If the script cannot be found, inform the user and stop.

### 1. Pre-flight Check

Check if `.aidlc-version` exists in the current directory:
- If it does NOT exist, inform the user that AI-DLC is not initialized and suggest running `/aidlc:init` first. Stop here.

Read the current version from `.aidlc-version`.

### 2. Check for Updates

Run the check subcommand:

```bash
AIDLC_TARGET_DIR="$(pwd)" bash "$FETCH_SCRIPT" check
```

Parse the output:
- `UP_TO_DATE <version>` — Inform the user they are already on the latest version. Stop here.
- `UPDATE_AVAILABLE <current> <latest>` — Continue to step 3.

### 3. Show Release Information

Fetch and display the release notes for the new version. Use:

```bash
gh api "repos/awslabs/aidlc-workflows/releases/tags/<latest_tag>" --jq '.body'
```

Or fall back to curl if `gh` is not available.

Present the update information:
- Current version → New version
- Release notes (if available)

Ask the user to confirm the update using AskUserQuestion, unless `--force` was passed.

### 4. Handle CLAUDE.md Conflicts

Check if the user has modified `CLAUDE.md` beyond what AI-DLC originally wrote (e.g., merged content from `/aidlc:init`).

A simple heuristic: if `CLAUDE.md` contains content that doesn't look like it came from AI-DLC (e.g., content before or after the AI-DLC rules block), warn the user that updating will overwrite `CLAUDE.md`.

Ask how to proceed:
1. **Overwrite**: Replace `CLAUDE.md` entirely with the new AI-DLC rules
2. **Merge**: Keep user content and update only the AI-DLC portion
3. **Cancel**: Abort the update

For "Merge":
1. Read the current `CLAUDE.md`
2. If it was merged during init (contains `---` separator), try to identify and replace only the AI-DLC portion
3. If unsure, append the new rules after a separator

### 5. Run Update

Execute the update:

```bash
AIDLC_TARGET_DIR="$(pwd)" bash "$FETCH_SCRIPT" update
```

If the user chose "Merge", handle the merge as described in step 4 (similar to the init merge flow).

### 6. Report Results

Summarize what was done:
- Previous version → New version
- Files updated
- Number of rule detail files
