# .agents

Personal AI agent assets, version-controlled.

This directory is the home for the bits of agent configuration you actually
own — your own skills, prompts, hooks, MCP servers, and rules — separate from
each tool's installed runtime.

## Layout

```
.agents/
├── skills/          your reusable agent skills (SKILL.md + helpers)
├── prompts/         reusable prompts (snippets, system prompts, templates)
├── rules/           rules / instructions you apply across tools
├── hooks/           hook scripts (pre/post agent events)
└── mcp/             MCP server configs you author or vendor
```

Each subdir is empty by default. Put a `.gitkeep` in any you want to keep
tracked while empty.

## How to wire each tool into `.agents/`

`install.sh` does **not** symlink anything from `.agents/` by default — the
right destination depends on each tool. Below are the common targets; pick
the ones you actually use.

### Claude (Code / Desktop)

Skills live in `~/.claude/skills/`. Symlink your authored skills:

```bash
mkdir -p ~/.claude/skills
for d in ~/dotfiles/.agents/skills/*/; do
  ln -sfn "$d" ~/.claude/skills/"$(basename "$d")"
done
```

### Cursor

User-level skills live in `~/.cursor/skills-cursor/`, rules in `~/.cursor/rules/`,
hooks in `~/.cursor/hooks/`. Same symlink pattern as above.

### MCP servers

If you author MCP server configs in `.agents/mcp/`, link them into the tool
that consumes them (Cursor: `~/.cursor/mcp.json`, Claude Code: project-level
`.claude/mcp.json`, etc.).

## Notes

- Skills are usually directories containing a `SKILL.md` plus optional helper
  scripts/templates. Keep one skill per subdirectory and use that
  subdirectory's name as the skill identifier.
- Anything you put here is committed to the public dotfiles repo by default —
  don't drop secrets in here. Use `~/.gitconfig.local` or environment files
  for credentials.
