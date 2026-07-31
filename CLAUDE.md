# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Historically, personal Ubuntu/Linux dotfiles managed with [Dotbot](https://github.com/anishathalye/dotbot)
(vendored as a git submodule at `dotbot/`). The owner no longer uses Linux day-to-day, so all the old Linux
configs/scripts have been moved into `archive/` (untouched, not deleted — see below) and this repo is being
repurposed for **Windows** config/dotfiles setup instead. `dotbot/` was kept at the root (not archived) since it
may be reused to manage the Windows setup too.

The repo currently holds no active config of its own — only `archive/` and the vendored `dotbot/` submodule.

There is no build, lint, or test tooling — this is a config repo, not a program. "Verifying" a change means
reading the shell/yaml/config for correctness, and (if actually applying it) checking the resulting symlinks or
script output.

## `archive/` — retired Linux dotfiles

`archive/` mirrors the repo's old root layout exactly (`archive/shell/`, `archive/git/`, `archive/sh/`,
`archive/backup/`, `archive/install`, `archive/install.conf.yaml`, `archive/install_scripts.sh`,
`archive/install_docker.sh`, `archive/backup_packages.sh`). It's kept for reference only — none of it is wired
up or expected to run. Do not resurrect it into active use without asking; do not delete it either.

Notable contents if you do need to look:
- `archive/install.conf.yaml` — the old Dotbot config: `link:` (symlink `~/.foo` → repo file), `clean: ["~"]`,
  and `shell:` (submodule sync + a dual-boot RTC fix + an inotify watch-limit fix).
- `archive/install.conf.yaml.back` — a stale/invalid leftover (not valid YAML) predating a repo reorg; not used
  by anything.
- `archive/shell/` — `bashrc`, `zshrc`, `profile`, `tmux.conf`, `p10k.zsh`, and two custom oh-my-zsh plugins.
- `archive/git/gitconfig` (+ `.gitconfig_local` for machine-specific overrides), `archive/sh/`,
  `archive/backup/` (package-manager snapshot files), `archive/backup_packages.sh`, `archive/install_scripts.sh`,
  `archive/install_docker.sh` — one-off Ubuntu bootstrap recipes (zsh/oh-my-zsh, Docker, apt/snap packages).

## Active layout (Windows)

- **Claude Code config is no longer kept here.** `claude/` (global `CLAUDE.md`, `settings.json`, skills)
  was removed on 2026-08-01 — the live files under `~/.claude` are the only copy, and this repo is not
  a backup for them. Don't re-add it without being asked. Never add `~/.claude/.credentials.json` or
  anything else containing tokens/secrets. The removed files remain in git history if they're needed.
- **`dotbot/`** — vendored upstream submodule (v1.24.1); don't hand-edit it. Not currently wired to
  anything (a symlink-based `install.conf.yaml`/`install.ps1` setup was tried and dropped — see above);
  kept in case a copy-based or elevated setup wants it later.
- **`.gitmodules`** — registers `dotbot`. The other commented-out submodule entries are historical and inactive.
