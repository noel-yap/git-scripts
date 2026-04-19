# git-scripts

A collection of small Git helper scripts I use for everyday workflows: cloning via a local cache, creating/reviewing/merging PRs, quick branching, and maintenance.

These scripts are intended to be placed somewhere on your PATH (e.g., `~/bin`) without the `.sh` extension in the command name. Example: invoke `git clone-with-cache`, not `git-clone-with-cache.sh`.

## Prerequisites
- Bash (some scripts use options available in modern Bash; macOS Homebrew Bash is used in a few scripts at `/opt/homebrew/bin/bash`).
- GitHub CLI `gh` for PR-related commands.
- macOS Google Chrome for opening PR URLs (used by `git edit-pr`).
- Atlassian CLI `acli` and `jq` for `git create-task` (used to fetch and parse task summaries when `ATLASSIAN_API_TOKEN` is set).
- An `ide` command (resolves to e.g. `idea` for IntelliJ IDEA or `ws` for WebStorm) if you use the `ct`/`rpr` aliases to auto-open workspaces.
- Some scripts rely on environment variables:
  - `GIT_DOMAIN` (e.g., `github.com`)
  - `GIT_ORG` (your organization/user)
- Recommended Git config:
  - `init.defaultBranch` set to your default branch name (e.g., `main`).

## Aliases

The repository includes a sample Git config (see `.gitconfig`) that defines handy `git` aliases wired to these scripts and a few useful Git shortcuts. Below is a quick reference of the aliases and what they do:

- `aliases` → `git config --get-regexp alias` — List all configured aliases.
- `bud` → `git mcb` — Alias for `git mcb`; make and checkout a branch off the current branch.
- `destash` → `git stash pop` — Apply the most recent stash and drop it.
- `cb` → `git-ch-branch.sh` — Switch to a branch.
- `clone-or-pull` → `git-clone-or-pull.sh` — Clone if missing, otherwise pull (see "git clone-or-pull").
- `ct` → `git-create-task.sh "$@"` — Create a task workspace and open it via `ide` (uses a wildcard to match the created directory; requires an `ide` command on PATH).
- `cwc` → `git-clone-with-cache.sh` — Clone via local cache (see "git clone-with-cache").
- `epr` → `git-edit-pr.sh` — Create a PR and open it (see "git edit-pr").
- `get` → `git-get.sh` — Fetch and switch to a remote branch (see "git get").
- `graft` → `git-graft.sh` — Rebase a branch (or all child branches) onto the current branch (see "git graft").
- `graph` → pretty `git log --graph` with branches/remotes/tags.
- `mb` → `git-mk-branch.sh` — Make a new branch with parent/union metadata recorded (see "git mcb").
- `mcb` → `git-mcb.sh` — Make and checkout a new branch (see "git mcb").
- `mpr` → `git-merge-pr.sh` — Merge the current PR via `gh` (see "git merge-pr").
- `push-pull` → `while ! git push; do git pull; done` — Keep trying to push, pulling if needed.
- `pwc` → `git-pull-with-cache.sh` — Update a mirror-backed repo and pull default branch (see "git pull-with-cache").
- `rb` → `git-sever.sh` — Force-delete local branches (name is historical; see "git sever").
- `reap` → `git-reap.sh` — Update cache, rebase on trunk (see "git reap").
- `rmcb` → `git-rmcb.sh` — Remove and recreate a branch (see "git rmcb").
- `rpr` → open the workspace created by `git-review-pr.sh` via `ide` — Review a PR locally (requires an `ide` command on PATH).
- `sever` → `git-sever.sh` — Force-delete local branches (see "git sever").
- `snapshot` → `git-snapshot.sh` — Quick working snapshot using stash (see "git snapshot").
- `sow` → `git-sow.sh` — Push the current branch; if an `upstream` remote exists, push with `--set-upstream upstream`.
- `uncommit` → `git reset HEAD^ --` — Undo last commit, keep changes in working tree.
- `unstage` → `git reset -q HEAD --` — Unstage changes, keep working tree as-is.

To use these, you can copy relevant entries into your global `~/.gitconfig`, or include this repo’s `.gitconfig` from your own config. Ensure the scripts are on your `PATH` without the `.sh` suffix as noted below.

## Branch stack workflow

`git bud`, `git graft`, and `git epr` work together to maintain a stack of branches and their corresponding PRs, where each branch builds on its parent. This is useful when you have dependent features that each need their own PR, or when you want to keep work-in-progress changes isolated while still building on each other.

### Core commands

| Command            | What it does                                                                                                        |
|--------------------|---------------------------------------------------------------------------------------------------------------------|
| `git bud «BRANCH»` | Create a branch, saving its parent and branch point for use by `git graft` and `git epr`                            |
| `git graft`        | Propagate changes from the current branch to all descendant branches                                                |
| `git epr`          | Create or update PRs for the branch stack, setting source and destination branches, then open all PR URLs in Chrome |

### Alias chain

- `git bud` → `git mcb` → `git mb` + `git cb` → `git-mk-branch.sh`
- `git graft` → `git-graft.sh`
- `git epr` → `git-edit-pr.sh` (requires `gh`; set `CHROME_PROFILE` if not using the `Default` Chrome profile)

### Setting up a branch stack

Starting from some branch, often `main`, or even from a detached HEAD, create a chain of branches with `git bud`. Each call records the current HEAD as the union point — the commit where the child branch diverges from its parent — as well as the parent itself.

```
git switch main
git bud feature          # create feature off main; record union = HEAD
# make commits on feature…
git bud subfeature       # create subfeature off feature; record union = HEAD
# make commits on subfeature…
```

The resulting history looks like:

```
main:       A
             \
feature:      B - C
                   \
subfeature:         D - E
```

To create PRs for the stack:

```
git epr                  # create/update PRs for all branches in the stack (ie all ancestor and descendent branches) and open them in Chrome
```

### Updating a parent branch

When `main` gets new commits, grafting replays the branch's commits on top of the updated parent. From `main` after it has advanced:

```
git switch main
git graft feature        # replay feature's commits onto updated main;
                         # then recursively replay subfeature onto updated feature
```

`git graft feature`:
1. Rebases `feature`'s commits (those in `union..feature`) onto the current `main` HEAD using `git rebase --onto`.
2. Recursively calls `git graft` on any child branches (e.g. `subfeature`), cascading the update down the stack.

### Grafting all children at once

When you're on a parent branch and want to update all of its direct children in one step:

```
git switch main
git graft                # graft all branches whose parent is main
```

### Resolving conflicts during a graft

If a graft runs into conflicts, the graft pauses just like a normal rebase would. Resolve the conflict as usual, then continue the graft and cascade the update down the rest of the stack:

```
# resolve conflicts in your editor…
git add «resolved-files»
git rebase --continue           # resume the in-progress rebase
git switch «original-branch»    # switch back to the branch you grafted onto
git graft                       # cascade the update to all child branches
```

### Creating a branch from detached HEAD

When in detached HEAD state (e.g. after `git checkout «SHA»`), use `--parent` to explicitly set the parent branch since there is no current branch to infer it from:

```
git bud --parent=«PARENT» «BRANCH»
git bud --parent=TRUNK «BRANCH»   # use init.defaultBranch as parent
```

## Scripts

### git bud
Alias for `git mcb`. See "git mcb" below.

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

### git create-task
Create a working directory for a task, clone the project into it, and create a branch named after the task. If `ATLASSIAN_API_TOKEN` is set, the Jira summary is fetched and included in the branch name.

Usage:
```
git create-task TASK_ID PROJECT
git create-task TASK_ID git@github.com:org/repo.git
git create-task https://jira.example.com/browse/TASK_ID PROJECT
git create-task 'https://jira.example.com/board?selectedIssue=TASK_ID' PROJECT
```
Arguments:
- `TASK_ID` — Jira issue key (e.g. `ABC-123`), or a Jira URL from which the key is extracted:
  - If the URL has a `selectedIssue` query parameter, that value is used as the task key (takes precedence over a `/browse/` path segment).
  - Otherwise if the URL path contains `/browse/TASK_ID`, that segment is used.
- `PROJECT` — name of the project directory to clone into, or a `git@host:org/repo.git` SSH URL from which the repo name is extracted. The full original value is always passed through to `git cwc`.

Behavior:
- If `ATLASSIAN_API_TOKEN` is set, looks up the task summary via Atlassian CLI (`acli`) and composes a branch/directory name of the form `TASK_ID：SUMMARY`. Otherwise uses just `TASK_ID`.
- Creates a subdirectory named after the branch and `cd`s into it.
- Runs `git cwc PROJECT` to set up the repo (requires your local `git cwc` helper).
- Inside the project, creates branch `TASK_ID：SUMMARY` (or `TASK_ID` if no token) and sets upstream.

### git edit-pr
Create GitHub pull requests for the current branch stack and open them all in Chrome.

Usage:
```
git edit-pr
CHROME_PROFILE='Profile 1' git edit-pr
```
Requirements:
- `gh` configured for the repo.
- macOS Chrome installed at `/Applications/Google Chrome.app`.
- `CHROME_PROFILE` environment variable set to your Chrome profile directory name (defaults to `Default` if not set).

Behavior:
- For each branch in the stack, if an `upstream` remote exists, fetches the parent branch from it before pushing.
- Creates (or updates) PRs for every ancestor branch between trunk and the current branch, then for every descendant branch, using `git sow` to push each branch.
- Opens all PR URLs in a single Chrome window in order: ancestors first, current branch, then descendants.

### git get
Fetch a branch from a remote (default `origin`) and switch to it.

Usage:
```
git get [REMOTE] BRANCH
```

### git graft
Propagate changes onto the current branch by rebasing a named branch or cherry-picking an explicit commit range. Requires a clean index (no staged changes).

Usage:
```
git graft
git graft «BRANCH»
git graft «LOWER»..«UPPER»
```
Behavior:
- No args: recursively grafts all child branches of the current branch (branches whose `branch.«name».parent` config matches the current branch). Errors if no child branches are found when called directly; warns if called recursively and a branch has no children.
- `«BRANCH»`: rebases commits in the range `«branch.«BRANCH».union»..«BRANCH»` onto the current branch using `git rebase --onto`, then recursively grafts any children of `«BRANCH»`. Requires `branch.«BRANCH».union` to be set (use `git bud` to create branches so this is set automatically). Errors if no union is found.
- `«LOWER»..«UPPER»`: cherry‑picks the explicit open-closed commit range onto the current branch with no branch metadata required.

### git mcb
Initialize a new repo (if outside a work tree) or make and checkout a new branch.

Usage:
```
git mcb [--parent=«PARENT»] «BRANCH»
```
Options:
- `--parent=«PARENT»` — explicitly set the parent branch. Use `--parent=TRUNK` to resolve the parent to `init.defaultBranch`. If omitted, defaults to the current branch. Fails with an error if the parent cannot be determined (e.g. detached HEAD).

Behavior:
- If not in a git work tree: `git init` (default branch taken from `init.defaultBranch`).
- Else: creates `«BRANCH»` recording `«PARENT»` as its parent and the current HEAD as its union point (used by `git graft`), then switches to it.

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
- Internally runs `git sever BRANCH` then `git mcb BRANCH`.

### git sever
Force‑delete one or more local branches.

Usage:
```
git sever BRANCH [BRANCH…]
```

### git sow
Push the current branch. If an `upstream` remote exists, push with `--set-upstream upstream HEAD` so the branch tracks the upstream remote.

Usage:
```
git sow [GIT_PUSH_OPTS…]
```
- Extra options (e.g. `--force-with-lease`) are passed through to `git push`.

### git snapshot
Create a quick working snapshot using stash and keep changes applied.

Usage:
```
git snapshot [STASH_OPTS…]
```
- Runs `git stash push` with the provided options, then `git stash apply`.

---

Tips
- If you use these frequently, consider adding shell completions or aliases.
- Adjust Chrome profile or paths in `git edit-pr` if needed.
