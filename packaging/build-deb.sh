#!/bin/sh
# Build the openvox-strings Debian packages from the current git checkout.
#
# Usage: packaging/build-deb.sh [extra dpkg-buildpackage arguments]
#
# Requires: git, dpkg-dev, debhelper and openvox-agent (from the OpenVox apt
# repository). Install the build dependencies with
# "mk-build-deps -i -r packaging/debian/control".
set -eu

topdir=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
cd "$topdir"

name=openvox-strings
gem=/opt/puppetlabs/puppet/bin/gem
upstream=$(sed -n "s/^ *VERSION = '\(.*\)'.*/\1/p" lib/openvox-strings/version.rb)
debversion=$(dpkg-parsechangelog -l packaging/debian/changelog -S Version)

if [ "${debversion%-*}" != "$upstream" ]; then
  echo "error: packaging/debian/changelog ($debversion) does not match gem version $upstream" >&2
  echo "       run: dch -c packaging/debian/changelog -v $upstream-1" >&2
  exit 1
fi

builddir="$topdir/pkg/debian"
srcdir="$builddir/$name-$upstream"
rm -rf "$builddir"
mkdir -p "$builddir/gems"

# Pristine upstream tarball from git HEAD (3.0 (quilt) source format).
git archive --format=tar --prefix="$name-$upstream/" HEAD \
  | gzip -n > "$builddir/${name}_$upstream.orig.tar.gz"

# Third-party gems go into the "gems" orig component tarball.
grep -v '^#' packaging/debian/vendor-gems | while read -r gemname version sha256; do
  [ -n "$gemname" ] || continue
  (cd "$builddir/gems" && "$gem" fetch "$gemname" --version "$version" --platform ruby >/dev/null)
  echo "$sha256  $builddir/gems/$gemname-$version.gem" | sha256sum -c --quiet
done
tar -C "$builddir" --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner -cf - gems \
  | gzip -n > "$builddir/${name}_$upstream.orig-gems.tar.gz"
rm -rf "$builddir/gems"

tar -C "$builddir" -xzf "$builddir/${name}_$upstream.orig.tar.gz"
tar -C "$srcdir" -xzf "$builddir/${name}_$upstream.orig-gems.tar.gz"
cp -a packaging/debian "$srcdir/debian"

cd "$srcdir"
dpkg-buildpackage -us -uc "$@"

echo "Packages written to $builddir"
