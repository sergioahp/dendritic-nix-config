# Giving Claude Code its own bash (instead of zsh)

Date: 2026-07-06. Claude Code 2.1.177, NixOS.

## How Claude Code picks its shell

Decoded from the CLI binary (function around offset 238402531 in
.claude-wrapped). Selection order:

1. `CLAUDE_CODE_SHELL` env var wins if BOTH hold:
   - the path string contains the substring "bash" or "zsh"
     (a /nix/store/...-bash-.../bin/bash qualifies)
   - the file is executable (X_OK check, with a `--version` fallback probe)
   On failure it logs "not a valid bash/zsh path" and falls through.
2. Otherwise, detection: candidate list ordered bash-first only when `$SHELL`
   contains "bash"; else zsh-first. Since $SHELL is zsh here, zsh won.

The chosen shell is spawned per Bash-tool command as:

    <shell> -c -l '<source snapshot> && <glob mitigation> && eval <cmd> && pwd -P >| <cwdfile>'

- `-l` login shell: on NixOS this sources /etc/profile, so PATH is fine.
- snapshot: a dump of the interactive shell's functions/aliases/options,
  written to ~/.claude/shell-snapshots/snapshot-<shell>-<ts>-<id>.sh and
  sourced before every command. The zsh snapshot here is 167 KB of fzf-tab
  and friends. A stock bash snapshot is near-empty.
- glob mitigation: `setopt NO_EXTENDED_GLOB NO_BARE_GLOB_QUAL` for zsh,
  `shopt -u extglob` for bash. This does NOT fix zsh's NOMATCH behavior:

      zsh  -c -l 'echo *.doesnotexist'  -> "no matches found", exit 1
      bash -c -l 'echo *.doesnotexist'  -> prints the pattern, exit 0

  which is exactly the "choking on glob" failure.

Telemetry field `executor_shell_overridden: Boolean(CLAUDE_CODE_SHELL)`
confirms the env var is a first-class supported override.

## Why the home-manager setting was not taking effect

hm-session-vars.sh does export
CLAUDE_CODE_SHELL=/nix/store/...-bash-interactive-5.3p9/bin/bash, but it
begins with:

    if [ -n "${__HM_SESS_VARS_SOURCED-}" ]; then return; fi

The running hyprland session exported __HM_SESS_VARS_SOURCED=1 before the
variable was added, so every shell/terminal spawned under it inherits the
guard and skips re-sourcing. Verified: the live claude process
(/proc/<pid>/environ) has __HM_SESS_VARS_SOURCED=1 and no CLAUDE_CODE_SHELL.
A full re-login (or hyprland restart) would fix it.

## Session-independent fix (recommended)

Set it in ~/.claude/settings.json via the "env" key, which Claude Code
applies to itself at startup regardless of how it was launched:

    "env": {
      "CLAUDE_CODE_SHELL": "/run/current-system/sw/bin/bash"
    }

/run/current-system/sw/bin/bash is a stable path (currently ->
bash-interactive-5.3p9), so no store path gets hardcoded and it survives
GC and rebuilds. The home-manager session variable can stay as a fallback;
after the next re-login both agree.

Verified locally that the exact spawn shape works with this bash:

    /run/current-system/sw/bin/bash -c -l 'shopt -u extglob ... && eval ...'
    -> BASH=5.3.9(1)-release, PATH populated, no-match globs pass through.

## Not verified yet (needs a new interactive session)

The end-to-end selection inside a real session. Headless `claude -p` is
API-billed on this account, so verification is manual: see instructions
in the session that produced this file. Expected markers:

- Bash tool reports $0 = /run/current-system/sw/bin/bash, BASH_VERSION set
- a new ~/.claude/shell-snapshots/snapshot-bash-*.sh appears (small)
- `claude --debug` stderr contains "Using shell override: ..."
