#!/bin/sh
# Build the openvox-strings RPM packages from the current git checkout.
#
# Usage: packaging/build-rpm.sh [extra rpmbuild arguments]
#
# Set OPENVOX_STRINGS_GEM to the path of a prebuilt openvox-strings gem to
# package that gem instead of building it from the checkout.
#
# Requires: git, rpm-build and openvox-agent (from the OpenVox yum repository).
set -eu

topdir=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
cd "$topdir"

name=openvox-strings
spec=packaging/rpm/$name.spec
gem=/opt/puppetlabs/puppet/bin/gem
upstream=$(sed -n "s/^ *VERSION = '\(.*\)'.*/\1/p" lib/openvox-strings/version.rb)
specversion=$(sed -n 's/^%global strings_version //p' "$spec")

if [ "$specversion" != "$upstream" ]; then
  echo "error: $spec ($specversion) does not match gem version $upstream" >&2
  exit 1
fi

rpmtop="$topdir/pkg/rpm"
rm -rf "$rpmtop"
mkdir -p "$rpmtop/SOURCES"

git archive --format=tar.gz --prefix="$name-$upstream/" -o "$rpmtop/SOURCES/$name-$upstream.tar.gz" HEAD

# Third-party gems, pinned in packaging/debian/vendor-gems (shared with the
# Debian packaging). The spec must use the same versions.
grep -v '^#' packaging/debian/vendor-gems | while read -r gemname version sha256; do
  [ -n "$gemname" ] || continue
  if ! grep -q "^%global ${gemname}_version $version\$" "$spec"; then
    echo "error: $spec does not set ${gemname}_version to $version" >&2
    exit 1
  fi
  (cd "$rpmtop/SOURCES" && "$gem" fetch "$gemname" --version "$version" --platform ruby >/dev/null)
  echo "$sha256  $rpmtop/SOURCES/$gemname-$version.gem" | sha256sum -c --quiet
done

if [ -n "${OPENVOX_STRINGS_GEM:-}" ]; then
  cp "$OPENVOX_STRINGS_GEM" "$rpmtop/SOURCES/$name-$upstream.gem"
  set -- --with prebuilt_gem "$@"
fi

rpmbuild --define "_topdir $rpmtop" -ba "$spec" "$@"

echo "Packages written to $rpmtop/RPMS and $rpmtop/SRPMS"
