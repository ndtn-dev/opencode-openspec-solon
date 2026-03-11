# Open Sourcing Notes

---

## Relationship to opencode-plugin-openspec

Solon is **inspired by** [opencode-plugin-openspec](https://github.com/Octane0411/opencode-plugin-openspec),
not derived from it.

### What was taken (inspiration)

- The concept of a read-only planning agent with scoped file permissions
- XML tag structure in the system prompt (`<Role>`, `<Rules>`)
- Permission pattern restricting writes to `openspec/**` and `specs/**`

These are general techniques, not proprietary code.

### What is original

- Single `.md` file format (vs TypeScript npm plugin)
- 5-phase architecture (intent gate, exploration, brainstorm, gap analysis, finalize)
- Intent classification with OpenSpec skill auto-triggers (6 intent types)
- Three-tier assumption tracking system (small/medium/big)
- Clearance check as conversational compass (adapted from OmO's Prometheus)
- Gap analysis with Metis delegation + self-review fallback
- Plan-to-spec conversion from any markdown source (Sisyphus, Claude, RFCs, freeform)
- .sisyphus integration (reads notepads, plans, drafts for design context)
- OmO ecosystem compatibility (hands off to Sisyphus, delegates to @metis)
- Brainstorm-first incremental artifact formation philosophy
- Session continuity via artifacts
- 9 design docs covering every behavioral decision

### Verdict

New project. Not a fork. Credit as inspiration in README.

---

## Pre-Publish Checklist

- [ ] Add MIT LICENSE file
- [ ] Credit opencode-plugin-openspec as inspiration in README
- [ ] Review solon.md for any project-specific references (should be generic)
- [ ] Decide on repo name (opencode-openspec-agent? solon-openspec? solon-agent?)
- [ ] Add install instructions to README (copy to .opencode/agents/)
- [ ] Consider adding screenshots/demo of the agent in action
- [ ] Tag v0.1.0

---

## License

MIT recommended — matches both OpenCode and opencode-plugin-openspec ecosystems.
