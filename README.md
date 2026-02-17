# claude-aidlc

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin that automates the setup and management of [AI-DLC (AI-Driven Development Life Cycle)](https://github.com/awslabs/aidlc-workflows) workflow rules.

## What is AI-DLC?

AI-DLC is a set of structured workflow rules from AWS Labs that guide AI coding agents through a disciplined software development lifecycle — from requirements analysis and design through implementation and operations.

## Installation

### From GitHub

```bash
# 1. Add as a marketplace
/plugin marketplace add shinichi-takahashi/claude-aidlc

# 2. Install the plugin
claude plugin install aidlc@shinichi-takahashi-claude-aidlc
```

### Local development

```bash
claude --plugin-dir /path/to/claude-aidlc
```

## Commands

### `/aidlc:init`

Initialize AI-DLC workflow rules in your current project.

```
/aidlc:init
```

This will:
- Download all rule files to `.aidlc-rule-details/`
- Append AI-DLC rules to `CLAUDE.md` with `<!-- aidlc:start/end -->` markers
- Record the installed version in `.aidlc-version`
- Optionally update `.gitignore`

If `CLAUDE.md` already exists, your content is preserved — AI-DLC rules are appended at the end.

### `/aidlc:update`

Check for and apply updates to AI-DLC rules.

```
/aidlc:update
```

This will:
- Check the currently installed version against the latest release
- Show release notes for the new version
- Update all rule files after confirmation

## File Layout

After initialization, your project will contain:

```
your-project/
├── CLAUDE.md              # Core workflow rules (commit this!)
├── .aidlc-version         # Installed version tag
└── .aidlc-rule-details/   # Detailed rule files
    ├── common/
    ├── inception/
    ├── construction/
    └── operations/
```

### What to commit?

| File | Commit? | Reason |
|------|---------|--------|
| `CLAUDE.md` | Yes | Share workflow rules with your team |
| `.aidlc-version` | Optional | Track which version is installed |
| `.aidlc-rule-details/` | Optional | Referenced by `CLAUDE.md` at runtime |

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- `curl` (for downloading files)
- `gh` CLI (optional, used for GitHub API calls with authentication)

## License

MIT
