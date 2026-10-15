# Installs the gems into the Ruby shipped with openvox-agent, producing the
# same files as "/opt/puppetlabs/puppet/bin/gem install openvox-strings".

%global strings_version 7.2.0
%global yard_version 0.9.45
%global rgen_version 0.10.2

%global aio_bindir  /opt/puppetlabs/puppet/bin
%global aio_gem     %{aio_bindir}/gem
%global aio_gem_dir %(%{aio_bindir}/ruby -e 'print Gem.default_dir' 2>/dev/null)

# The gem directory depends on the Ruby ABI, which only changes with a new
# openvox-agent major release.
%global agent_major %(rpm -q --qf '%%{version}' openvox-agent 2>/dev/null | cut -d. -f1)
%global agent_requires openvox-agent >= %{agent_major}, openvox-agent < %(expr %{agent_major} + 1 2>/dev/null)

# Keep the files exactly as "gem install" creates them and do not derive
# dependencies from the gem contents.
%global __brp_mangle_shebangs %{nil}
%global debug_package %{nil}
AutoReqProv: no

Name:           openvox-strings
Version:        %{strings_version}
Release:        1%{?dist}
Summary:        Generate documentation for OpenVox code using YARD
License:        Apache-2.0
URL:            https://github.com/voxpupuli/openvox-strings
Source0:        %{name}-%{strings_version}.tar.gz
Source1:        https://rubygems.org/downloads/yard-%{yard_version}.gem
Source2:        https://rubygems.org/downloads/rgen-%{rgen_version}.gem
BuildArch:      noarch
BuildRequires:  openvox-agent

Requires:       %{agent_requires}
AutoReqProv:    no
Requires:       openvox-gem-yard >= 0.9, openvox-gem-yard < 1.0
Requires:       openvox-gem-rgen >= 0.9, openvox-gem-rgen < 0.11

%description
openvox-strings generates documentation for Puppet code and extensions
written in Puppet and Ruby. It processes code and YARD-style code comments
to create documentation in HTML, Markdown, or JSON formats.

This package installs the openvox-strings gem into the Ruby shipped with
openvox-agent, equivalent to running
"/opt/puppetlabs/puppet/bin/gem install openvox-strings". It provides the
"puppet strings" subcommand and rake tasks for module development.

%package -n openvox-gem-yard
Version:        %{yard_version}
Summary:        YARD documentation tool for the openvox-agent Ruby
License:        MIT
URL:            https://yardoc.org
Requires:       %{agent_requires}
AutoReqProv:    no

%description -n openvox-gem-yard
YARD is a documentation generation tool for the Ruby programming language.

This package installs the yard gem into the Ruby shipped with openvox-agent,
including the yard, yardoc and yri commands in /opt/puppetlabs/puppet/bin.

%package -n openvox-gem-rgen
Version:        %{rgen_version}
Summary:        Ruby modelling and generator framework for the openvox-agent Ruby
License:        MIT
URL:            https://github.com/mthiede/rgen
Requires:       %{agent_requires}
AutoReqProv:    no

%description -n openvox-gem-rgen
RGen is a framework for model-driven development in Ruby. openvox-strings
uses it to parse Puppet code.

This package installs the rgen gem into the Ruby shipped with openvox-agent.

%prep
%setup -q -n %{name}-%{strings_version}

%build
%{aio_gem} build %{name}.gemspec --output %{name}-%{strings_version}.gem

%install
gem_install() {
  %{aio_gem} install --local --ignore-dependencies --no-user-install \
    --document ri \
    --install-dir %{buildroot}%{aio_gem_dir} \
    --bindir %{buildroot}%{aio_bindir} \
    "$1"
}
gem_install %{SOURCE1}
gem_install %{SOURCE2}
gem_install %{name}-%{strings_version}.gem

%files
%license LICENSE
%doc README.md JSON.md
%{aio_gem_dir}/gems/%{name}-%{strings_version}
%{aio_gem_dir}/specifications/%{name}-%{strings_version}.gemspec
%{aio_gem_dir}/cache/%{name}-%{strings_version}.gem
%{aio_gem_dir}/doc/%{name}-%{strings_version}

%files -n openvox-gem-yard
%{aio_bindir}/yard
%{aio_bindir}/yardoc
%{aio_bindir}/yri
%{aio_gem_dir}/gems/yard-%{yard_version}
%{aio_gem_dir}/specifications/yard-%{yard_version}.gemspec
%{aio_gem_dir}/cache/yard-%{yard_version}.gem
%{aio_gem_dir}/doc/yard-%{yard_version}
%{aio_gem_dir}/plugins/yard_plugin.rb

%files -n openvox-gem-rgen
%{aio_gem_dir}/gems/rgen-%{rgen_version}
%{aio_gem_dir}/specifications/rgen-%{rgen_version}.gemspec
%{aio_gem_dir}/cache/rgen-%{rgen_version}.gem
%{aio_gem_dir}/doc/rgen-%{rgen_version}

%changelog
* Thu Oct 15 2026 Jörn Ott <joern.ott@ott-consult.de> - 7.2.0-1
- Initial packaging: install openvox-strings, yard and rgen into the
  openvox-agent Ruby.
