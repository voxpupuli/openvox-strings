# Packaging

This directory contains the metadata to build native OS packages of
openvox-strings for Debian/Ubuntu (`debian/`) and RHEL/EL, Fedora and
SLES/openSUSE (`rpm/`).

Both formats build the same three packages that install gems into the Ruby
shipped with `openvox-agent` (`/opt/puppetlabs/puppet`):

| Package            | Content                                   |
| ------------------ | ----------------------------------------- |
| `openvox-strings`  | the openvox-strings gem built from this repository |
| `openvox-gem-yard` | the yard gem, including `yard`, `yardoc`, `yri` in `/opt/puppetlabs/puppet/bin` |
| `openvox-gem-rgen` | the rgen gem                              |

Installing them yields the same files as
`/opt/puppetlabs/puppet/bin/gem install openvox-strings` (gems, specifications,
cached `.gem` files, ri documentation and binstubs). All packages depend on
the `openvox-agent` major version they were built against, because the gem
directory (`lib/ruby/gems/<abi>`) follows the agent's Ruby version.

The versions of yard and rgen are pinned with SHA-256 checksums in
`debian/vendor-gems`, which both build scripts use.

## Debian / Ubuntu

### Building

The build host needs the OpenVox apt repository (see
<https://voxpupuli.org/openvox/install/>) because `openvox-agent` is a build
dependency, and network access to rubygems.org to fetch the pinned gems.

```sh
sudo apt-get install git devscripts equivs
sudo mk-build-deps -i -r packaging/debian/control
packaging/build-deb.sh
```

The script creates the upstream tarball from `git HEAD`, fetches and verifies
the gems listed in `debian/vendor-gems` into a second `orig-gems` tarball,
adds the `debian/` directory and runs `dpkg-buildpackage`. Results end up in
`pkg/debian/`.

### Updating

* New openvox-strings version: add a matching changelog entry first,
  `dch -c packaging/debian/changelog -v <version>-1`.
* New yard or rgen version: update version and checksum in
  `debian/vendor-gems` (`sha256sum` of the `.gem` from rubygems.org) and keep
  the version ranges in `debian/control` in line with the gemspec.

## RHEL / EL, Fedora, SLES / openSUSE

### Building

The build host needs the OpenVox yum repository (see
<https://voxpupuli.org/openvox/install/>) because `openvox-agent` is a build
dependency, and network access to rubygems.org to fetch the pinned gems.

```sh
sudo dnf install git rpm-build openvox-agent         # EL, Fedora
sudo zypper install git rpm-build openvox-agent      # SLES, openSUSE
packaging/build-rpm.sh
rpmlint -f packaging/rpm/openvox-strings.rpmlintrc pkg/rpm/RPMS/noarch/*.rpm  # rpmlint 2.x: -r
```

The script creates the source tarball from `git HEAD`, fetches and verifies
the gems listed in `debian/vendor-gems` and runs `rpmbuild -ba`. Results end
up in `pkg/rpm/RPMS/` and `pkg/rpm/SRPMS/`.

### Updating

* New openvox-strings version: update `strings_version` and add a
  `%changelog` entry in `rpm/openvox-strings.spec`.
* New yard or rgen version: update `debian/vendor-gems` and the matching
  `yard_version`/`rgen_version` in the spec, and keep the version ranges in
  the spec in line with the gemspec. The build script refuses to run if the
  versions differ.
