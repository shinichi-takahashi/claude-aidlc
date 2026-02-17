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

### 1. Pre-flight Checks

Check if `.aidlc-version` already exists in the current directory:
- If it exists, inform the user that AI-DLC is already initialized and suggest using `/aidlc:update` instead. Show the current version from `.aidlc-version`. Stop here unless the user passed `--force`.

Check if `CLAUDE.md` already exists in the current directory:
- If it exists, ask the user to choose one of:
  1. **Backup**: Rename existing `CLAUDE.md` to `CLAUDE.md.bak` and replace with AI-DLC rules
  2. **Merge**: Append AI-DLC rules to the end of the existing `CLAUDE.md` (separated by a horizontal rule)
  3. **Cancel**: Abort the operation
- Use the AskUserQuestion tool to present these choices.

### 2. Run Fetch Script

Execute the fetch script to download the latest AI-DLC rules:

```bash
AIDLC_TARGET_DIR="$(pwd)" bash "$FETCH_SCRIPT" init
```

If the user chose "Merge" in step 1:
1. First, read the original `CLAUDE.md` content
2. Run the fetch script (which will overwrite `CLAUDE.md`)
3. Read the newly downloaded `CLAUDE.md` (AI-DLC rules)
4. Write the merged file: original content + `\n\n---\n\n` + AI-DLC rules

If the user chose "Backup" in step 1:
1. Rename `CLAUDE.md` to `CLAUDE.md.bak`
2. Run the fetch script

### 3. Suggest .gitignore Updates

Check if `.gitignore` exists and whether it already contains the relevant entries. Suggest adding:
```
.aidlc-rule-details/
.aidlc-version
```

Explain that `CLAUDE.md` is intentionally NOT in `.gitignore` because it should be committed for team sharing.

Use the AskUserQuestion tool to ask if the user wants to add these entries.

### 4. Report Results

Summarize what was done:
- Version installed
- Files created/modified
- Number of rule detail files downloaded
- Remind the user they can run `/aidlc:update` later to check for updates
