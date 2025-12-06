# git-scripts

A collection of small Git helper scripts I use for everyday workflows: cloning via a local cache, creating/reviewing/merging PRs, quick branching, and maintenance.

These scripts are intended to be placed somewhere on your PATH (e.g., `~/bin`) without the `.sh` extension in the command name. Example: invoke `git clone-with-cache`, not `git-clone-with-cache.sh`.

## Prerequisites
- Bash (some scripts use options available in modern Bash; macOS Homebrew Bash is used in a few scripts at `/opt/homebrew/bin/bash`).
- GitHub CLI `gh` for PR-related commands.
- macOS Google Chrome for opening PR URLs (used by `git create-pr`).
- Some scripts rely on environment variables:
  - `GIT_DOMAIN` (e.g., `github.com`)
  - `GIT_ORG` (your organization/user)
- Recommended Git config:
  - `init.defaultBranch` set to your default branch name (e.g., `main`).

## Aliases

The repository includes a sample Git config (see `.gitconfig`) that defines handy `git` aliases wired to these scripts and a few useful Git shortcuts. Below is a quick reference of the aliases and what they do:

- `aliases` → `git config --get-regexp alias` — List all configured aliases.
- `destash` → `git stash pop` — Apply the most recent stash and drop it.
- `cb` → `git-cb.sh` — Switch to a branch (see "git cb").
- `clone-or-pull` → `git-clone-or-pull.sh` — Clone if missing, otherwise pull (see "git clone-or-pull").
- `cpr` → `git-create-pr.sh` — Create a PR and open it (see "git create-pr").
- `ct` → `git-create-task.sh "$@" && idea "$1/$2"` — Create a task workspace and open it in IntelliJ IDEA (requires `idea` launcher).
- `cwc` → `git-clone-with-cache.sh` — Clone via local cache (see "git clone-with-cache").
- `get` → `git-get.sh` — Fetch and switch to a remote branch (see "git get").
- `graft` → `git-graft.sh` — Recreate a branch by cherry-picking a range (see "git graft").
- `graph` → pretty `git log --graph` with branches/remotes/tags.
- `mb` → `git branch` — Short alias for listing/managing branches.
- `mcb` → `git-mcb.sh` — Make and checkout a new branch (see "git mcb").
- `mpr` → `git-merge-pr.sh` — Merge the current PR via `gh` (see "git merge-pr").
- `push-pull` → `while ! git push; do git pull; done` — Keep trying to push, pulling if needed.
- `pwc` → `git-pull-with-cache.sh` — Update a mirror-backed repo and pull default branch (see "git pull-with-cache").
- `rb` → `git-shear.sh` — Force-delete local branches (name is historical; see "git shear").
- `reap` → `git-reap.sh` — Update cache, rebase on trunk (see "git reap").
- `rmcb` → `git-rmcb.sh` — Remove and recreate a branch (see "git rmcb").
- `rpr` → open the workspace created by `git-review-pr.sh` in IDEA — Review a PR locally (requires `idea`).
- `shear` → `git-shear.sh` — Force-delete local branches (see "git shear").
- `snapshot` → `git-snapshot.sh` — Quick working snapshot using stash (see "git snapshot").
- `sow` → `git push` — Push the current branch.
- `sprout` → `git-sprout.sh` — Init or create a namespaced feature branch (see "git sprout").
- `uncommit` → `git reset HEAD^ --` — Undo last commit, keep changes in working tree.
- `unstage` → `git reset -q HEAD --` — Unstage changes, keep working tree as-is.
- `upstream-set` → `github-upstream-set.sh` — Helper to set upstream remotes (requires your local script).

To use these, you can copy relevant entries into your global `~/.gitconfig`, or include this repo’s `.gitconfig` from your own config. Ensure the scripts are on your `PATH` without the `.sh` suffix as noted below.

## Scripts

### git cb
Switch to a branch.

Usage:
```
git cb [BRANCH_NAME]
```
- If `BRANCH_NAME` is `-`, switches to the previous branch (`@{-1}`).
- If omitted, switches to the repo’s configured `init.defaultBranch`.

### git clone-or-pull
Clone a repo if missing, otherwise `git pull` in the existing directory.

Usage:
```
git clone-or-pull [GIT_CLONE_OPTS…] REPO_URL [DIR]
```
- Example: `git clone-or-pull --depth 1 https://github.com/user/proj.git`.

### git clone-with-cache
Clone a repository via a local cache mirror to speed up repeated clones, and set the push URL to SSH.

Usage:
```
GIT_DOMAIN=github.com GIT_ORG=my-org git clone-with-cache PROJECT_NAME
```
- Creates/updates a cache at `~/.cache/git/${GIT_DOMAIN}/${GIT_ORG}`.
- Clones from the local cache into `./PROJECT_NAME`.
- Sets push URL to `git@${GIT_DOMAIN}:${GIT_ORG}/${PROJECT_NAME}.git`.

### git create-pr
Create a GitHub pull request from the current branch and open it in Chrome.

Usage:
```
git create-pr
```
Requirements:
- `gh` configured for the repo.
- macOS Chrome installed at `/Applications/Google Chrome.app` (uses profile `Profile 1`).

### git create-task
Create a working directory for a task, clone the project into it, create a branch, and push it upstream.

Usage:
```
git create-task TASK_NAME PROJECT_NAME
```
Behavior:
- Creates a subdirectory named `TASK_NAME/` and `cd`s into it.
- Runs `git cwc PROJECT_NAME` to set up the repo (requires your local `git cwc` helper).
- Inside the project, creates and pushes branch `TASK_NAME`.

### git get
Fetch a branch from a remote (default `origin`) and switch to it.

Usage:
```
git get [REMOTE] BRANCH
```

### git graft
Recreate a branch by cherry‑picking a range of commits onto a fresh branch of the same name. Requires a clean index (no staged changes).

Usage:
```
git graft BRANCH
git graft LOWER..UPPER
```
- If given `BRANCH`, picks commits from `BRANCH~..BRANCH` in chronological order.
- Deletes and recreates the branch, then cherry‑picks each commit.

### git mcb
Make and checkout a new branch.

Usage:
```
git mcb BRANCH
```

### git merge-pr
Merge the current pull request using `gh`.

Usage:
```
git merge-pr
```

### git pull-with-cache
Update a repository when `origin` points to a local mirror and then pull the default branch from the remote.

Usage:
```
git pull-with-cache
```
Notes:
- Expects `origin` fetch URL to be a local path (e.g., a mirrored checkout).
- Pulls in the mirror, then pulls the repo’s `init.defaultBranch` from `origin`.

### git reap
Rebase the current branch on top of trunk after ensuring a cache directory is up to date.

Usage:
```
git reap
```
Behavior:
- Updates `~/.cache/grail` (custom cache; adjust to your setup).
- Switches to `init.defaultBranch`, pulls, switches back, and rebases onto trunk.

### git review-pr
Prepare a local workspace to review a PR URL: clone (or update) the repo, fetch the PR’s head branch, and switch to it.

Usage:
```
GIT_DOMAIN=github.com GIT_ORG=my-org git review-pr https://github.com/my-org/proj/pull/1234
```
Requirements:
- `gh` configured and authenticated.
- `git clone-or-pull` available on PATH.
Behavior:
- Creates a directory named after the PR’s head branch and clones the project inside it.
- Adds fetch for the PR branch, fetches it, and checks it out.

### git rmcb
Remove a branch locally (force) and immediately recreate it and switch to it.

Usage:
```
git rmcb BRANCH
```
- Internally runs `git shear BRANCH` then `git mcb BRANCH`.

### git shear
Force‑delete one or more local branches.

Usage:
```
git shear BRANCH [BRANCH…]
```

### git snapshot
Create a quick working snapshot using stash and keep changes applied.

Usage:
```
git snapshot [STASH_OPTS…]
```
- Runs `git stash push` with the provided options, then `git stash apply`.

### git sprout
Initialize a new repo (if outside a work tree) or create a namespaced feature branch.

Usage:
```
git sprout FEATURE_NAME
```
Behavior:
- If not in a git work tree: `git init` (default branch is taken from your global `init.defaultBranch`).
- Else: creates and switches to branch `${USER}/FEATURE_NAME`.

---

Tips
- If you use these frequently, consider adding shell completions or aliases.
- Adjust Chrome profile or paths in `git create-pr` if needed.
