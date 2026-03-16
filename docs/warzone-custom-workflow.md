# WarZone Custom Upgrade Workflow

This repository is set up to keep custom TerraformGenerator changes while still upgrading from upstream.

## Current remotes

- `origin` -> `https://github.com/Hex27/TerraformGenerator`
- `myfork` -> `https://github.com/kgustine/TerraformGenerator`

## Branches

- `master`: upstream baseline
- `upstream-main`: local mirror of `origin/master`
- `warzone-custom`: your custom feature stack

## One-time setup status

Already completed in this repo:

- `warzone-custom` branch created and pushed to `myfork/warzone-custom`
- `upstream-main` branch created to track `origin/master`
- Git rebase helpers enabled:
  - `rerere.enabled = true`
  - `rerere.autoupdate = true`
  - `rebase.autoStash = true`
- Patch backups exported under `patches/warzone-custom/`

## Normal upgrade flow

Run from repository root:

```powershell
git fetch origin
git switch warzone-custom
git rebase origin/master
```

If conflicts occur:

```powershell
# edit files to resolve

git add <resolved-files>
git rebase --continue
```

If you need to abort:

```powershell
git rebase --abort
```

Push updated custom branch to your fork:

```powershell
git push myfork warzone-custom --force-with-lease
```

## Optional: refresh local upstream mirror branch

```powershell
git branch -f upstream-main origin/master
```

## Optional: regenerate patch backups

```powershell
New-Item -ItemType Directory -Path patches/warzone-custom -Force | Out-Null
git format-patch origin/master..warzone-custom -o patches/warzone-custom
```

## Recovery options

- Re-apply commits from your branch:
  - `git cherry-pick origin/master..warzone-custom`
- Re-apply exported patches:
  - `git am patches/warzone-custom/*.patch`

## Notes

- Keep custom features in small, focused commits. This reduces conflict cost when rebasing.
- Existing generated world chunks will not retroactively regenerate structures after logic/config changes.
