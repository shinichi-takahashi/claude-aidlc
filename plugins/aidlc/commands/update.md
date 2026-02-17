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

**Important**: The fetch script downloads `core-workflow.md` into `.aidlc-rule-details/core-workflow.md` — it does NOT touch `CLAUDE.md` directly. You are responsible for updating `CLAUDE.md` using marker comments.

## Marker Format

AI-DLC rules in `CLAUDE.md` are wrapped with these markers:

```
<!-- aidlc:start -->
{contents of .aidlc-rule-details/core-workflow.md}
<!-- aidlc:end -->
```

On update, find and replace **only** the content between these markers. All other content in `CLAUDE.md` is preserved.

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
  📁 Project (./):           v0.1.2
  🏠 User root (~/.claude/): v0.1.2
  🌐 Latest available:       v0.1.3
```

Based on the detected state:

**Case A — Neither location has AI-DLC:**
Inform the user that AI-DLC is not initialized anywhere. Suggest running `/aidlc:init` first. Stop here.

**Case B — Installation(s) found, all already up to date:**
Inform the user they are already on the latest version. Stop here.

**Case C — Only one location has AI-DLC (update available):**
Show the update info and proceed to step 2.

**Case D — Both locations have AI-DLC:**
Show versions for both. Ask the user using AskUserQuestion:
1. **Update project only**: Update only the project directory
2. **Update user root only**: Update only the user root
3. **Update both**: Update both locations
4. **Cancel**: Abort

(Skip locations that are already up to date — don't offer to "update" something that's current.)

### 2. Show Release Information

Fetch and display the release notes for the new version:

```bash
gh api "repos/awslabs/aidlc-workflows/releases/tags/<latest_tag>" --jq '.body'
```

Or fall back to curl if `gh` is not available.

Present the update information:
- Current version → New version
- Release notes (if available)

Ask the user to confirm the update using AskUserQuestion, unless `--force` was passed.

### 3. Run Update

Execute the update for each selected target:

For project directory:
```bash
AIDLC_TARGET_DIR="$(pwd)" bash "$FETCH_SCRIPT" update
```

For user root:
```bash
AIDLC_TARGET_DIR="$HOME/.claude" bash "$FETCH_SCRIPT" update
```

### 4. Update CLAUDE.md

For each updated target directory, read the new core workflow rules:
```bash
cat <target>/.aidlc-rule-details/core-workflow.md
```

Then read the corresponding `CLAUDE.md` and look for the marker block:
```
<!-- aidlc:start -->
...
<!-- aidlc:end -->
```

**If markers are found:**
Replace everything between `<!-- aidlc:start -->` and `<!-- aidlc:end -->` (inclusive) with:
```
<!-- aidlc:start -->
{new core-workflow.md contents}
<!-- aidlc:end -->
```

All content outside the markers is preserved as-is.

**If markers are NOT found (legacy installation or manual setup):**
Warn the user that `CLAUDE.md` doesn't contain AI-DLC markers. Ask using AskUserQuestion:
1. **Append**: Add the new rules at the end with markers
2. **Overwrite**: Replace entire `CLAUDE.md` with markers + new rules
3. **Skip**: Don't update `CLAUDE.md` (only rule detail files are updated)

Use the Write tool to write the updated `CLAUDE.md`.

### 5. Report Results

Summarize what was done:
- Previous version → New version (for each updated location)
- Files updated
- Number of rule detail files
