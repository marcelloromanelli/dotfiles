# .agents

Personal AI agent assets, version-controlled.

## Skills

Skills live under `skills/<name>/SKILL.md`. They are auto-linked into both
`~/.cursor/skills/` and `~/.claude/skills/` by `./install.sh link`, so any
skill added here becomes immediately available in Cursor and Claude Code on
the next session.

Current skills:

- **dotfiles** — editing, syncing, and debugging this repo
- **onboard-new-mac** — bootstrapping a fresh Mac to match this setup

To add a new skill:

```bash
mkdir -p .agents/skills/my-skill
${EDITOR:-vim} .agents/skills/my-skill/SKILL.md      # follow the create-skill format
./install.sh link                                     # symlinks into both tools
dots sync "agents: add my-skill"
```

A skill's `SKILL.md` needs YAML frontmatter:

```yaml
---
name: my-skill
description: WHAT it does, plus WHEN the agent should reach for it. Third person.
---
```

See [Cursor skill docs](https://docs.cursor.com/skills) and the `create-skill`
skill (bundled with Cursor) for the full format.

## Other planned subdirs

These are scaffolded but currently empty. Populate as needed; nothing is
auto-linked beyond `skills/`.

```
.agents/
├── skills/          (auto-linked into ~/.cursor/skills + ~/.claude/skills)
├── prompts/         reusable prompts (snippets, system prompts, templates)
├── rules/           rules / instructions you apply across tools
├── hooks/           hook scripts (pre/post agent events)
└── mcp/             MCP server configs you author or vendor
```

## Notes

- Skills MUST follow the `create-skill` format (YAML frontmatter + markdown
  body, max 500 lines). The pre-commit hook does not currently validate this
  — be careful when authoring.
- Anything you put here is committed to the public dotfiles repo by default.
  Don't drop secrets in here. Use `~/.extra` (via `op://` references) for
  credentials.
