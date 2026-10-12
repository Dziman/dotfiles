#!/bin/zsh
# Tests for git-delete-branch in ~/.zsh-dziman/565_git.enabled.zsh, against
# throwaway repos whose shared branch is main.
# Run: zsh ~/.dziman/tests/git-delete-branch-test.zsh
set -u

# The file's chpwd hook needs colour settings from other startup files
add-zsh-hook() { : }
source "${0:A:h}/../../.zsh-dziman/565_git.enabled.zsh"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com
export GIT_CONFIG_GLOBAL=/dev/null
failed=0
assert() { # assert <description> <command...>
  local desc=$1; shift
  if "$@"; then echo "ok   $desc"; else echo "FAIL $desc"; failed=1; fi
}
not() { ! "$@"; }
current_branch_is() { [[ "$(git branch --show-current)" == "$1" ]]; }
has_local_branch() { git show-ref --quiet --verify "refs/heads/$1"; }
has_remote_branch() { git ls-remote --exit-code --heads origin "$1" >/dev/null; }

# fixture: a remote whose default branch is main, and a working copy on feature/x
# <name> <how>: `clone` records the remote's default branch, `push` does not
make_repo() {
  local name=$1 how=$2
  git init -q --bare -b main "$tmp/$name.git"
  git init -q -b main "$tmp/seed-$name"
  git -C "$tmp/seed-$name" commit -q --allow-empty -m first
  git -C "$tmp/seed-$name" push -q "$tmp/$name.git" main
  if [[ $how == clone ]]; then
    git clone -q "$tmp/$name.git" "$tmp/$name"
  else
    git init -q -b main "$tmp/$name"
    git -C "$tmp/$name" remote add origin "$tmp/$name.git"
    git -C "$tmp/$name" fetch -q origin
    # git 2.48+ records the default branch on fetch; forget it like an older clone would
    git -C "$tmp/$name" remote set-head origin -d
    git -C "$tmp/$name" switch -q main
  fi
  git -C "$tmp/$name" switch -q -c feature/x
  git -C "$tmp/$name" push -q origin feature/x
}

make_repo cloned clone
cd "$tmp/cloned"
git-delete-branch feature/x >/dev/null 2>&1
assert "deleting the current branch lands on the remote's default branch" current_branch_is main
assert "deleted branch is gone locally" not has_local_branch feature/x
assert "deleted branch is gone on the remote" not has_remote_branch feature/x

make_repo pushed push
cd "$tmp/pushed"
assert "fixture: the default branch is not recorded yet" not git rev-parse -q --verify refs/remotes/origin/HEAD
git-delete-branch feature/x >/dev/null 2>&1
assert "remote's default branch is found even when the clone never recorded it" current_branch_is main

make_repo other clone
cd "$tmp/other"
git switch -q -c feature/y
git-delete-branch feature/x >/dev/null 2>&1
assert "deleting another branch keeps the current one" current_branch_is feature/y

exit $failed
