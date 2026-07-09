# zsh vs bash as Claude Code's shell

Date: 2026-07-06. Method: 15 test cases of shell idioms the model commonly
emits, each run through the exact spawn shape Claude Code uses
(bash: `shopt -u extglob`; zsh: `setopt NO_NOMATCH NO_EXTENDED_GLOB
NO_BARE_GLOB_QUAL`, i.e. zsh with the proposed glob fix already applied).
Test files: bashisms/t*.sh. Raw outputs in the session transcript.

## Results

Class 1 - silent wrong behavior in zsh (no error, different result):

| test                | bash            | zsh+NO_NOMATCH               |
|---------------------|-----------------|------------------------------|
| t01 $var splitting  | [-a][-b]        | [-a -b] (one word)           |
| t03 echo "a\nb"     | literal \n      | real newline                 |
| t07 BASH_REMATCH    | major=5         | major= (empty)               |
| t08 ${a[0]}         | first element   | empty (arrays 1-indexed)     |
| t13 EPOCHSECONDS    | epoch seconds   | empty (needs zsh/datetime)   |

Class 2 - loud errors in zsh (visible, costs a retry turn):

| test                     | zsh failure                          |
|--------------------------|--------------------------------------|
| t02 path=... as variable | clobbers PATH; command not found: ls |
| t04 ${v^^}               | bad substitution                     |
| t05 ${!ref}              | bad substitution                     |
| t06 mapfile              | command not found                    |
| t09 ${!map[@]}           | bad substitution                     |
| t12 shopt in a command   | command not found (rc=127)           |
| t14 read -p              | -p: no coprocess; var left empty     |

Class 3 - zsh wins:

| test              | bash                                | zsh          |
|-------------------|-------------------------------------|--------------|
| t10 **/*.nix      | silently non-recursive (globstar    | recursive by |
|                   | off; missed flake.nix and nested    | default      |
|                   | modules/shells/cli-shell.nix)       |              |

t11 (no-match glob) and t15 (word starting with =) were fine in both,
t11 thanks to NO_NOMATCH.

## Other observations

- Snapshot size on this machine: bash 3.4 KB (zero aliases, PATH correctly
  captured) vs interactive zsh 167 KB. A dedicated wrapped zsh would also
  be small, so this favors "dedicated shell", not bash per se.
- The tool the model uses is literally named Bash and its description
  promises bash; the model emits bash idioms accordingly. The harness
  itself only patches zsh globbing, nothing else on the list above.
- Remote boxes (vast.ai/runpod/hyperstack) have $SHELL=bash, so Claude
  uses bash there. Local bash = identical shell semantics local/remote;
  local zsh = two dialects depending on where the session runs.
- zsh can be pushed closer to bash (SH_WORD_SPLIT, KSH_ARRAYS,
  BASH_REMATCH, BSD_ECHO setopts) but that still leaves mapfile, ${v^^},
  ${!ref}, ${!map[@]}, shopt, read -p, EPOCHSECONDS broken. Best case is
  a worse bash.

## Conclusion

Use bash for Claude's shell. NO_NOMATCH fixes only 1 of the ~12 zsh
divergences found; 5 are silent wrong-results, which are worse than
errors. The single bash regression (** not recursive, silent) is
mitigated by the model's dedicated Glob/Grep tools and could be flipped
on in the wrapped bash config if desired.
