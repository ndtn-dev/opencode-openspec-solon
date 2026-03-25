## 1. Create solon-debug skill

- [ ] 1.1 Create claude/skills/solon-debug/SKILL.md (and opencode/skills/solon-debug/SKILL.md)
- [ ] 1.2 Implement diagnostic check sequence: CLI installed -> project initialized -> skills present -> profile check -> version staleness
- [ ] 1.3 Implement remediation: openspec update --force, write version marker to .solon/openspec-version.txt
- [ ] 1.4 Set allowed-tools: Bash, Read, Glob

## 2. Update solon-spec Phase 1

- [ ] 2.1 Add skill presence gate: check for .claude/skills/openspec-explore/SKILL.md, .claude/skills/openspec-new-change/SKILL.md, .claude/skills/openspec-continue-change/SKILL.md
- [ ] 2.2 Add stop + point to /solon-debug if any missing
- [ ] 2.3 Add explore delegation to openspec-explore skill
- [ ] 2.4 Remove any existing direct-write fallback logic

## 3. Update solon-spec Phase 6

- [ ] 3.1 Replace direct artifact writes with sub-agent dispatch
- [ ] 3.2 Sub-agent prompt template: include confirmed content + invoke openspec-new-change then openspec-continue-change by skill name
- [ ] 3.3 Add content fence instruction: "{{DEFERRED: not addressed in current spec cycle}}" for unfilled sections
- [ ] 3.4 Add failure handling: if skill invocation fails, stop and point to /solon-debug
- [ ] 3.5 Preserve locked-state rule

## 4. Update solon-handoff

- [ ] 4.1 Add post-implementation workflow section to handoff document template
- [ ] 4.2 Reference: openspec-apply-change -> openspec-verify-change -> openspec-archive-change
- [ ] 4.3 Include brief description of each step's purpose

## 5. Simplify solon-init

- [ ] 5.1 Remove the "which openspec" CLI pre-flight check
- [ ] 5.2 Add failure handler: if openspec init --tools Claude fails, stop and point to /solon-debug
- [ ] 5.3 Keep git repo warning, git remote warning, already-initialized check unchanged

## 6. Archive stale doc

- [ ] 6.1 Move docs/openspec-integration.md to docs/.archive/openspec-integration.md

## 7. Update solon-eval test cases

- [ ] 7.1 Review solon-eval test expectations against new behavior (e.g., Init test should expect /solon-debug reference on failure, not direct CLI install instructions)
