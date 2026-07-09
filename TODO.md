# TODO

## Claude Code gets its own shell

Drop the in-claude-else branching: the user zsh becomes fully user-flavored
(cat=bat, ls=eza, ...) and Claude Code gets a dedicated stock bash so it
feels at home (no zsh NOMATCH globbing, no 167 KB interactive snapshot).
Investigation notes: experiments/claude-shell/findings.md

- [ ] Alias option: perSystem zsh.shellAliases (attrsOf str) declared in
      modules/zsh.nix, rendered into .zshrc with escapeShellArg. Any flake
      part can contribute its own aliases; conditional ones use mkIf.
- [ ] Remove in-claude-else and the CLAUDECODE-branching aliases.
- [ ] New part modules/claude-shell.nix: packages.claude-bash, a wrapped
      bash with its own config: a chosen subset of the shared aliases plus
      claude-specific bits. Constraints found in the binary: the path must
      contain the substring "bash"; Claude spawns it as `bash -c -l` and
      sources a snapshot of the shell env before every command, and the
      snapshot starts with `unalias -a`, so config likely needs to go in
      via BASH_ENV (verify aliases survive the snapshot round-trip).
- [ ] Point CLAUDE_CODE_SHELL at the stable path (settings.json env block
      or home manager; never a hardcoded store path).
- [ ] Verify in a fresh session: $0 is our bash, BASH_VERSION set, a small
      snapshot-bash-*.sh appears in ~/.claude/shell-snapshots/.
- [ ] Decide alias split: shared vs zsh-only vs claude-only. If sharing is
      real, promote to a shell-agnostic option (e.g. cli.shellAliases) that
      both zsh and claude-bash consume.
