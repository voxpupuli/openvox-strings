#!/bin/sh
# Verify that installing the packages gives the same result as
#   /opt/puppetlabs/puppet/bin/gem install openvox-strings
#
# Usage: packaging/test/compare-install.sh <openvox-strings gem> <package>...
#
# Packages are .deb or .rpm files built by packaging/build-deb.sh or
# packaging/build-rpm.sh. Run as root on a system with openvox-agent and none
# of the gems or packages installed. The script
#
# 1. installs the gem with the openvox-agent gem command, resolving yard and
#    rgen from the versions pinned in packaging/debian/vendor-gems,
# 2. records mode, owner, type and SHA-256 of everything in /opt/puppetlabs,
# 3. uninstalls the gems and installs the packages instead,
# 4. compares both states and runs "puppet strings" on a sample module,
# 5. removes the packages and checks that /opt/puppetlabs is back to the
#    original state.
set -eu

if [ "$#" -lt 2 ]; then
  sed -n '2,/^set -eu/p' "$0" | sed '$d; s/^# \{0,1\}//' >&2
  exit 2
fi
if [ "$(id -u)" -ne 0 ]; then
  echo "error: must run as root" >&2
  exit 2
fi

topdir=$(cd "$(dirname "$0")/../.." && pwd)
strings_gem=$(realpath "$1")
shift
packages=""
for p in "$@"; do packages="$packages $(realpath "$p")"; done

bindir=/opt/puppetlabs/puppet/bin
gem="$bindir/gem"
gemdir=$("$bindir/ruby" -e 'print Gem.default_dir')
gems="openvox-strings yard rgen"
pkgnames="openvox-strings openvox-gem-yard openvox-gem-rgen"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

failed=0
fail() {
  echo "::error::$*"
  failed=1
}

snapshot() {
  find /opt/puppetlabs -printf '%m %u:%g %y %p\n' | sort -k4 > "$1.meta"
  find /opt/puppetlabs -type f -print0 | sort -z | xargs -0 sha256sum > "$1.sum"
}

compare() {
  # compare <name a> <name b> <description>
  meta_ok=0 sum_ok=0
  diff -u "$work/$1.meta" "$work/$2.meta" > "$work/meta.diff" || meta_ok=$?
  diff -u "$work/$1.sum" "$work/$2.sum" > "$work/sum.diff" || sum_ok=$?
  if [ "$meta_ok" -ne 0 ] || [ "$sum_ok" -ne 0 ]; then
    fail "$3"
    head -n 50 "$work/meta.diff" "$work/sum.diff"
    return 1
  fi
  echo "OK: $3 ($(wc -l < "$work/$2.sum") files compared)"
}

if [ -n "$(command -v apt-get)" ]; then
  pkg_install() { DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends "$@"; }
  pkg_remove() { DEBIAN_FRONTEND=noninteractive apt-get purge -y -q "$@"; }
elif [ -n "$(command -v zypper)" ]; then
  pkg_install() { zypper -n --no-gpg-checks install "$@"; }
  pkg_remove() { zypper -n remove "$@"; }
else
  pkg_install() { dnf -y install "$@"; }
  pkg_remove() { dnf -y remove "$@"; }
fi

echo "== Preparing gems"
mkdir "$work/gems"
cp "$strings_gem" "$work/gems/"
grep -v '^#' "$topdir/packaging/debian/vendor-gems" | while read -r name version sha256; do
  [ -n "$name" ] || continue
  (cd "$work/gems" && "$gem" fetch "$name" --version "$version" --platform ruby >/dev/null)
  echo "$sha256  $work/gems/$name-$version.gem" | sha256sum -c --quiet
  latest=$("$gem" list --remote --exact "$name" 2>/dev/null | sed -n "s/^$name (\([^ ,)]*\).*/\1/p")
  if [ -n "$latest" ] && [ "$latest" != "$version" ]; then
    echo "::warning::$name $latest is available on rubygems.org, packages pin $version (packaging/debian/vendor-gems)"
  fi
done

snapshot "$work/base"

echo "== Installing with gem install"
(cd "$work/gems" && "$gem" install --local --no-user-install "$(basename "$strings_gem")")
snapshot "$work/gem"

echo "== Uninstalling gems"
# shellcheck disable=SC2086
"$gem" uninstall --all --executables $gems
# gem uninstall leaves the (empty) documentation directories behind
for name in $gems; do
  find "$gemdir/doc" -mindepth 1 -maxdepth 1 -type d -name "$name-*" -exec rm -rf {} +
done
snapshot "$work/clean"
compare base clean "gem uninstall restores the original state" || exit 1

echo "== Installing packages"
# shellcheck disable=SC2086
pkg_install $packages
snapshot "$work/pkg"
compare gem pkg "package installation matches gem install" || true

echo "== Running puppet strings"
module="$work/module"
mkdir -p "$module/manifests" "$module/lib/puppet/functions"
cat > "$module/manifests/init.pp" <<'EOF'
# @summary A demo class
# @param msg The message to print
class demo (String $msg = 'hi') {
  notify { $msg: }
}
EOF
cat > "$module/lib/puppet/functions/double.rb" <<'EOF'
# @summary Doubles a number
Puppet::Functions.create_function(:'demo::double') do
  # @param x Input
  # @return [Integer] Doubled
  dispatch :double do
    param 'Integer', :x
  end

  def double(x)
    x * 2
  end
end
EOF
if (cd "$module" && /opt/puppetlabs/bin/puppet strings generate --format json --out "$work/strings.json") \
  && "$bindir/ruby" -rjson -e '
    j = JSON.parse(File.read(ARGV[0]))
    exit(j["puppet_classes"].map { |c| c["name"] } == ["demo"] &&
         j["puppet_functions"].map { |f| f["name"] } == ["demo::double"])
  ' "$work/strings.json"; then
  echo "OK: puppet strings documents the sample module"
else
  fail "puppet strings did not produce the expected documentation"
fi
"$bindir/yard" --version

echo "== Removing packages"
# shellcheck disable=SC2086
pkg_remove $pkgnames
snapshot "$work/removed"
compare base removed "package removal restores the original state" || true

if [ "$failed" -ne 0 ]; then
  echo "FAILED"
  exit 1
fi
echo "All checks passed"
