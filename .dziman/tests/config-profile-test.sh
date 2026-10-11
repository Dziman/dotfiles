#!/bin/sh
# Tests for ~/.local/bin/config-profile in a throwaway $HOME with its own bare repo.
# Run: sh ~/.dziman/tests/config-profile-test.sh
set -u

script=$(cd "$(dirname "$0")/../.." && pwd)/.local/bin/config-profile
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
DZIMAN_DOTFILES="$tmp/none" run one
assert "activation works" test "$(cat "$HOME/.ssh/config")" = one
echo r > "$HOME/.norepo"
DZIMAN_DOTFILES="$tmp/none" run adopt "$HOME/.norepo"
assert "adopt works" test -L "$HOME/.norepo" -a -f "$profiles/one/.norepo"
DZIMAN_DOTFILES="$tmp/none" run unadopt "$HOME/.norepo"
assert "unadopt works" test -f "$HOME/.norepo" -a ! -L "$HOME/.norepo"

echo "# names"
run bogus
assert "unknown profile is refused" test $? -eq 2
run ../x
assert "a path is not a name" test $? -eq 2
run
assert "no argument shows usage" test $? -eq 2

exit $failed
