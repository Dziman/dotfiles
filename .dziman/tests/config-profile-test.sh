#!/bin/sh
# Tests for ~/.local/bin/git-profile and the ~/.local/bin/config wrapper, in a
# throwaway $HOME with its own bare repo.
# Run: sh ~/.dziman/tests/config-profile-test.sh
set -u

bin=$(cd "$(dirname "$0")/../.." && pwd)/.local/bin
script=$bin/git-profile
config=$bin/config
PATH="$bin:$PATH"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home"
export DZIMAN_DOTFILES="$tmp/dotfiles.git"
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com
profiles="$HOME/.dziman/profiles"
cfg() { git -C "$HOME" --git-dir="$DZIMAN_DOTFILES" --work-tree="$HOME" "$@"; }
run() { "$script" "$@" >"$tmp/out" 2>"$tmp/err"; }
failed=0
assert() { # assert <description> <command...>
  desc=$1; shift
  if "$@"; then echo "ok   $desc"; else echo "FAIL $desc"; failed=1; fi
}
links_to() { [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ]; }
not() { ! "$@"; }
is_tracked() { cfg ls-files --error-unmatch -- "$1" >/dev/null 2>&1; }
is_staged() { ! cfg diff --cached --quiet -- "$1"; }
lists_in_status() { cfg status --porcelain -uall | grep -qF "$1"; }

# fixture: two profiles, a tracked shared file, one untracked neighbour in $HOME
mkdir -p "$HOME" "$profiles/one/.ssh" "$profiles/one/.gradle/init.d" "$profiles/two/.ssh" "$HOME/.gradle/init.d"
echo one > "$profiles/one/.ssh/config"
echo two > "$profiles/two/.ssh/config"
echo repo > "$profiles/one/.gradle/init.d/repos.gradle"
echo mine > "$HOME/.gradle/init.d/local.gradle"
printf '.ssh/config\n# a directory entry\n.gradle/init.d\n' > "$profiles/one/links"
printf '.ssh/config\n' > "$profiles/two/links"
echo shared > "$HOME/.shared"
printf 'ignored.txt\n.dziman/profile\n' > "$HOME/.gitignore"
mkdir -p "$profiles/one/Library/Application Support/App"
echo plist > "$profiles/one/Library/Application Support/App/a b.plist"
echo 'Library/Application Support/App' >> "$profiles/one/links"
mkdir -p "$profiles/three"; ln -s ../one/.ssh "$profiles/three/.ssh"; printf '.ssh/config\n' > "$profiles/three/links"
git init -q --bare "$DZIMAN_DOTFILES"
echo '/my-own-rule' > "$DZIMAN_DOTFILES/info/exclude"
cfg add .shared .gitignore .dziman/profiles >/dev/null
cfg commit -q -m fixture

echo "# activation"
run one
assert "activation prints the profile" grep -qx 'profile: one' "$tmp/out"
assert "links a file through ~/.dziman/profile" links_to "$HOME/.ssh/config" "../.dziman/profile/.ssh/config"
assert "the link resolves" test "$(cat "$HOME/.ssh/config")" = one
assert "a directory entry links each file" links_to "$HOME/.gradle/init.d/repos.gradle" "../../.dziman/profile/.gradle/init.d/repos.gradle"
assert "untracked neighbour is kept" test -f "$HOME/.gradle/init.d/local.gradle"
assert "links are excluded from git status" grep -q '^/\.ssh/config$' "$DZIMAN_DOTFILES/info/exclude"
assert "git status does not list them" not lists_in_status '.ssh/config'
assert "a path with a space is linked" test "$(cat "$HOME/Library/Application Support/App/a b.plist")" = plist
assert "hand-written exclude rules survive" grep -qx '/my-own-rule' "$DZIMAN_DOTFILES/info/exclude"

run --show
assert "--show prints the name" test "$(cat "$tmp/out")" = one

echo "# switching"
run two
assert "the new profile's file is linked" test "$(cat "$HOME/.ssh/config")" = two
assert "a link the new profile lacks is removed" test ! -e "$HOME/.gradle/init.d/repos.gradle" -a ! -L "$HOME/.gradle/init.d/repos.gradle"
assert "the removed link leaves the exclude list" not grep -q 'repos.gradle' "$DZIMAN_DOTFILES/info/exclude"
run one
sed -i '' '/^Library/d' "$profiles/one/links"
run one
assert "a link whose entry left the manifest is removed" test ! -L "$HOME/Library/Application Support/App/a b.plist"
assert "and its exclude line" not grep -qF 'a b.plist' "$DZIMAN_DOTFILES/info/exclude"
run two

echo "# a real file in the way"
rm "$HOME/.ssh/config"; echo keep > "$HOME/.ssh/config"
run one
assert "exit status is 1" test $? -eq 1
assert "the file is reported" grep -q 'in the way: ~/.ssh/config' "$tmp/err"
assert "the file is untouched" test "$(cat "$HOME/.ssh/config")" = keep
assert "other links are still made" test -L "$HOME/.gradle/init.d/repos.gradle"
assert "the profile is switched anyway" test "$(readlink "$HOME/.dziman/profile")" = profiles/one

echo "# status"
rm "$HOME/.gradle/init.d/repos.gradle"
echo stray > "$profiles/one/stray.txt"
run status
assert "shadowed path" grep -q '^shadowed  ~/.ssh/config$' "$tmp/out"
assert "missing link" grep -q '^missing   ~/.gradle/init.d/repos.gradle$' "$tmp/out"
assert "untracked profile file" grep -q '^untracked .dziman/profiles/one/stray.txt$' "$tmp/out"
rm "$HOME/.ssh/config" "$profiles/one/stray.txt"
run one
run status
assert "ok link" grep -q '^ok        ~/.ssh/config$' "$tmp/out"
rm "$profiles/one/.ssh/config"
run status
assert "broken link" grep -q '^broken    ~/.ssh/config$' "$tmp/out"
run one
assert "a listed file missing from the profile fails activation" test $? -eq 1
assert "and is named" grep -q 'no such file in the profile: .ssh/config' "$tmp/err"
echo one > "$profiles/one/.ssh/config"
run one

echo "# adopt"
mkdir -p "$HOME/.pip"; echo pip > "$HOME/.pip/pip.conf"
run adopt "$HOME/.pip/pip.conf"
assert "the file moves into the profile" test "$(cat "$profiles/one/.pip/pip.conf")" = pip
assert "it is linked" links_to "$HOME/.pip/pip.conf" "../.dziman/profile/.pip/pip.conf"
assert "it is listed" grep -qx '.pip/pip.conf' "$profiles/one/links"
assert "it is staged" is_staged .dziman/profiles/one/.pip/pip.conf
run adopt "$HOME/.shared" < /dev/null
assert "a tracked file is not moved without a yes" test $? -eq 1 -a -f "$HOME/.shared" -a ! -L "$HOME/.shared"
assert "and the warning explains the move" grep -q 'tracked for every machine' "$tmp/err"
assert "and nothing is staged" not is_staged .shared
echo y | run adopt "$HOME/.shared"
assert "with a yes it is tracked at its profile path" is_tracked .dziman/profiles/one/.shared
assert "and no longer at the old one" not is_tracked .shared
assert "and linked" test "$(cat "$HOME/.shared")" = shared
mkdir -p "$HOME/Local/AS"; echo a > "$HOME/Local/AS/a.conf"; echo b > "$HOME/Local/AS/b.conf"
(cd "$HOME/Local" && "$script" adopt AS >"$tmp/out" 2>"$tmp/err")
assert "a relative directory is adopted whole" test -f "$profiles/one/Local/AS/a.conf" -a -f "$profiles/one/Local/AS/b.conf"
assert "with one link per file" links_to "$HOME/Local/AS/b.conf" "../../.dziman/profile/Local/AS/b.conf"
assert "and one manifest line" grep -qx 'Local/AS' "$profiles/one/links"
echo x > "$HOME/ignored.txt"
run adopt "$HOME/ignored.txt"
assert "an ignored file is refused" test $? -eq 1
assert "and stays where it was" test -f "$HOME/ignored.txt"
run adopt /etc/hosts
assert "a path outside \$HOME is refused" test $? -eq 1
run adopt "$HOME/.ssh/config"
assert "an existing link is refused" test $? -eq 1
mkdir -p "$HOME/d.dir"; echo d > "$HOME/d.dir/f"
run adopt "$HOME/d.dir/."
assert "a dot path is refused" test $? -eq 1
run unadopt "$HOME/.shared"
assert "a tracked file comes back tracked at its old path" is_tracked .shared
assert "and is a real file again" test -f "$HOME/.shared" -a ! -L "$HOME/.shared"

echo "# unadopt"
run unadopt "$HOME/.pip/pip.conf"
assert "the file is back in \$HOME" test -f "$HOME/.pip/pip.conf" -a ! -L "$HOME/.pip/pip.conf"
assert "gone from the profile" test ! -e "$profiles/one/.pip/pip.conf"
assert "unlisted" not grep -qx '.pip/pip.conf' "$profiles/one/links"
assert "no longer tracked in the profile" not is_tracked .dziman/profiles/one/.pip/pip.conf
assert "but at its \$HOME path" is_tracked .pip/pip.conf
run unadopt "$HOME/Local/AS"
assert "a directory comes back whole" test -f "$HOME/Local/AS/a.conf" -a ! -L "$HOME/Local/AS/a.conf" -a ! -e "$profiles/one/Local"
run unadopt "$HOME/.gradle/init.d/local.gradle"
assert "an unlisted path is refused" test $? -eq 1
rm "$HOME/.ssh/config"; echo LOCAL > "$HOME/.ssh/config"
run unadopt "$HOME/.ssh/config"
assert "a shadowed file is not overwritten" test $? -eq 1 -a "$(cat "$HOME/.ssh/config")" = LOCAL
assert "and the profile copy stays" test -f "$profiles/one/.ssh/config"
rm "$HOME/.ssh/config"; run one

echo "# a profile directory that is a symlink"
run three
echo n > "$HOME/.ssh/new"
run adopt "$HOME/.ssh/new"
assert "adopt through the symlink is refused" test $? -eq 1
assert "and the file stays in \$HOME" test -f "$HOME/.ssh/new"
run unadopt "$HOME/.ssh/config"
assert "unadopt through the symlink is refused" test $? -eq 1
assert "and the other profile's file stays" test -f "$profiles/one/.ssh/config"
rm "$HOME/.ssh/new"

echo "# without a bare repo"
norepo() { DZIMAN_DOTFILES="$tmp/none" "$script" "$@" >"$tmp/out" 2>"$tmp/err"; }
norepo one
assert "activation works" test "$(cat "$HOME/.ssh/config")" = one
echo r > "$HOME/.norepo"
norepo adopt "$HOME/.norepo"
assert "adopt works" test -L "$HOME/.norepo" -a -f "$profiles/one/.norepo"
norepo unadopt "$HOME/.norepo"
assert "unadopt works" test -f "$HOME/.norepo" -a ! -L "$HOME/.norepo"

echo "# names"
run bogus
assert "unknown profile is refused" test $? -eq 2
run ../x
assert "a path is not a name" test $? -eq 2
run
assert "no argument shows usage" test $? -eq 2
assert "usage points at --help" grep -q -- '--help' "$tmp/err"
run links
assert "links lists the active profile's linked files" test "$(cat "$tmp/out")" = "$(printf '.ssh/config\n.gradle/init.d/repos.gradle')"
run --help
assert "--help exits 0" test $? -eq 0
assert "and explains adopt" grep -q 'adopt' "$tmp/out"
assert "and the profile link" grep -qF '~/.dziman/profile' "$tmp/out"
run -h
assert "-h is the same" test $? -eq 0 -a -s "$tmp/out"

echo "# config wrapper"
cfgw() { "$config" "$@" >"$tmp/out" 2>"$tmp/err"; }
echo changed >> "$profiles/one/.ssh/config"
cfgw status --porcelain
assert "status names a linked file by its \$HOME path" grep -qx ' M ~/.ssh/config' "$tmp/out"
assert "and leaves other paths alone" sh -c "echo x >> '$HOME/.shared'; '$config' status --porcelain | grep -qx ' M .shared'"
cfgw status
assert "long status too" grep -q 'modified:   ~/.ssh/config' "$tmp/out"
cfgw add "$HOME/.ssh/config"
assert "a link argument is translated to the tracked file" is_staged .dziman/profiles/one/.ssh/config
cfgw status --porcelain
assert "and shows as staged under the \$HOME path" grep -qx 'M  ~/.ssh/config' "$tmp/out"
cfgw diff --cached --name-only
assert "other commands are passed through unchanged" grep -qx '.dziman/profiles/one/.ssh/config' "$tmp/out"
cfgw profile --show
assert "config profile reaches git-profile" test "$(cat "$tmp/out")" = one
cfg checkout -q -- .shared; cfg reset -q -- .dziman/profiles/one/.ssh/config; cfg checkout -q -- .dziman/profiles/one/.ssh/config

echo "# through git with another work tree"
( cd "$tmp" && git --git-dir="$DZIMAN_DOTFILES" --work-tree="$tmp" profile --show >"$tmp/out" 2>"$tmp/err" )
assert "refused when the work tree is not \$HOME" test $? -eq 1

echo "# rollout"
# fixture: a source repo with branch old (checked out in a second HOME) and branch new
src="$tmp/src"; git init -q -b old "$src"
( cd "$src" && echo shared > .shared && mkdir -p .oldzsh && echo x > .oldzsh/a.zsh && git add -A && git commit -q -m old \
  && git switch -q -c new && git rm -q -r .oldzsh && echo new > .newfile && mkdir -p .dziman/profiles/one/.ssh \
  && echo one > .dziman/profiles/one/.ssh/config && printf '.ssh/config\n' > .dziman/profiles/one/links \
  && printf '.dziman/profile\n.dziman/rollout-backup/\n' > .gitignore \
  && git add -A && git commit -q -m new && git switch -q old )
git clone -q --bare "$src" "$tmp/roll.git"
H2="$tmp/home2"; mkdir -p "$H2"
git --git-dir="$tmp/roll.git" --work-tree="$H2" checkout -q old
echo mine > "$H2/.newfile"; mkdir -p "$H2/.ssh"; echo LOCAL > "$H2/.ssh/config"; : > "$H2/.zcompdump"
roll() { HOME="$H2" DZIMAN_DOTFILES="$tmp/roll.git" "$script" "$@" >"$tmp/out" 2>"$tmp/err"; }
r2() { git -C "$H2" --git-dir="$tmp/roll.git" --work-tree="$H2" "$@"; }
( cd "$tmp" && roll rollout new one )
assert "refused outside \$HOME" test $? -eq 2
assert "with a message naming \$HOME" grep -q 'from \$HOME' "$tmp/err"
echo edit >> "$H2/.shared"
( cd "$H2" && roll rollout new one )
assert "refused while a tracked file is modified" test $? -eq 1
assert "naming it" grep -q '\.shared' "$tmp/err"
assert "and nothing moved" test "$(cat "$H2/.newfile")" = mine -a "$(r2 branch --show-current)" = old
r2 checkout -q -- .shared
( cd "$H2" && roll rollout nope one )
assert "unknown ref is refused" test $? -eq 1
( cd "$H2" && roll rollout new one )
assert "rollout succeeds" test $? -eq 0
assert "branch switched" test "$(r2 branch --show-current)" = new
assert "profile active" test "$(readlink "$H2/.dziman/profile")" = profiles/one
backup=$(ls -d "$H2"/.dziman/rollout-backup/* | head -1)
assert "the untracked file in the way is backed up" test "$(cat "$backup/.newfile")" = mine
assert "and the tracked one checked out" test "$(cat "$H2/.newfile")" = new
assert "the real file at a link path is backed up" test "$(cat "$backup/.ssh/config")" = LOCAL
assert "and linked" links_to "$H2/.ssh/config" "../.dziman/profile/.ssh/config"
assert "the backups are listed" grep -q 'rollout-backup' "$tmp/out"
assert "zcompdump removed" test ! -e "$H2/.zcompdump"
assert "an emptied old directory is removed" test ! -d "$H2/.oldzsh"
assert "status is clean" test -z "$(r2 status --porcelain)"

exit $failed
