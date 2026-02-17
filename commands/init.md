---
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - AskUserQuestion
description: "Initialize AI-DLC workflow rules in the current project"
argument-hint: "[--force]"
---

# /aidlc:init — Initialize AI-DLC Workflow Rules

You are setting up AI-DLC (AI-Driven Development Life Cycle) workflow rules from [awslabs/aidlc-workflows](https://github.com/awslabs/aidlc-workflows) in the current project.

**Important**: The fetch script downloads `core-workflow.md` into `.aidlc-rule-details/core-workflow.md` — it does NOT touch `CLAUDE.md` directly. You are responsible for writing `CLAUDE.md` using marker comments.

## Marker Format

When writing AI-DLC rules into `CLAUDE.md`, always wrap them with these markers:

```
<!-- aidlc:start -->
{contents of .aidlc-rule-details/core-workflow.md}
<!-- aidlc:end -->
```

These markers allow `/aidlc:update` to find and replace only the AI-DLC section without touching the user's own content.

## Steps

### 0. Locate Plugin Script

Use the Glob tool to find `fetch-aidlc.sh`. Search in this order (first match wins):

1. **Project root** (current working directory):
```
pattern: "**/claude-aidlc/scripts/fetch-aidlc.sh"
path: ".claude"
```

2. **User root** (fallback):
```
pattern: "**/claude-aidlc/scripts/fetch-aidlc.sh"
path: "~/.claude"
```

3. If still not found, try broader patterns:
```
pattern: "**/aidlc/scripts/fetch-aidlc.sh"
```
in both `.claude` and `~/.claude`.

Store the resolved absolute path as `FETCH_SCRIPT` for use in later steps. If the script cannot be found, inform the user and stop.

### 1. Detect Existing Installations

Check for `.aidlc-version` in **both** locations:
- **Project directory**: `./.aidlc-version` (current working directory)
- **User root**: `~/.claude/.aidlc-version`

Also fetch the latest available version:
```bash
gh api repos/awslabs/aidlc-workflows/releases/latest --jq '.tag_name'
```

Present a status summary to the user. Example:
```
AI-DLC status:
  📁 Project (./):           not installed
  🏠 User root (~/.claude/): v0.1.2
  🌐 Latest available:       v0.1.3
```

Based on the detected state, determine the action:

**Case A — Project has no AI-DLC, user root has no AI-DLC:**
Proceed with installing to the project directory.

**Case B — Project already has AI-DLC:**
Inform the user and suggest `/aidlc:update` instead. Stop here unless `--force` was passed.

**Case C — Project has no AI-DLC, but user root does:**
Ask the user using AskUserQuestion:
1. **Install to project only**: Install AI-DLC rules in the current project directory
2. **Update user root too**: Install to project AND update user root to the latest version
3. **Cancel**: Abort

### 2. Run Fetch Script

Execute the fetch script to download rule files into `.aidlc-rule-details/`:

```bash
AIDLC_TARGET_DIR="$(pwd)" bash "$FETCH_SCRIPT" init
```

If the user also chose to update user root (Case C, option 2):
```bash
AIDLC_TARGET_DIR="$HOME/.claude" bash "$FETCH_SCRIPT" update
```

### 3. Write CLAUDE.md

Read the downloaded core workflow rules:
```bash
cat .aidlc-rule-details/core-workflow.md
```

**If `CLAUDE.md` does NOT exist:**
Create it with the AI-DLC rules wrapped in markers:
```
<!-- aidlc:start -->
{core-workflow.md contents}
<!-- aidlc:end -->
```

**If `CLAUDE.md` already exists:**
Read the existing content. The AI-DLC rules should be **appended** to the existing content, wrapped in markers:
```
{existing CLAUDE.md content}

<!-- aidlc:start -->
{core-workflow.md contents}
<!-- aidlc:end -->
```

Use the Write tool to write the final `CLAUDE.md`.

If user root is also being updated, apply the same logic for `~/.claude/CLAUDE.md`.

### 4. Suggest .gitignore Updates

Check if `.gitignore` exists and whether it already contains the relevant entries. Suggest adding:
```
.aidlc-rule-details/
.aidlc-version
```

Explain that `CLAUDE.md` is intentionally NOT in `.gitignore` because it should be committed for team sharing.

Use the AskUserQuestion tool to ask if the user wants to add these entries.

### 5. Report Results

Summarize what was done:
- Version installed (and where)
- Files created/modified
- Number of rule detail files downloaded
- If user root was also updated, mention that too
- Remind the user they can run `/aidlc:update` later to check for updates
