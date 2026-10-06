# openvox-strings

[![License](https://img.shields.io/github/license/voxpupuli/openvox-strings.svg)](https://github.com/voxpupuli/openvox-strings/blob/master/LICENSE)
[![Release](https://github.com/voxpupuli/openvox-strings/actions/workflows/release.yml/badge.svg)](https://github.com/voxpupuli/openvox-strings/actions/workflows/release.yml)
[![Test](https://github.com/voxpupuli/openvox-strings/actions/workflows/ci.yml/badge.svg)](https://github.com/voxpupuli/openvox-strings/actions/workflows/ci.yml)
[![RubyGem Version](https://img.shields.io/gem/v/openvox-strings.svg)](https://rubygems.org/gems/openvox-strings)
[![RubyGem Downloads](https://img.shields.io/gem/dt/openvox-strings.svg)](https://rubygems.org/gems/openvox-strings)

openvox-strings generates documentation for Puppet code and extensions written in Puppet and Ruby.
Strings processes code and YARD-style code comments to create documentation in HTML, Markdown, or JSON formats.

It's a fork of https://github.com/puppetlabs/puppet-strings.

## Installing openvox-strings

### Requirements

* Ruby 3.2 or newer
* OpenVox 8.24 or newer

For detailed dependencies, please checkout the gemspec file.

### Install openvox-strings

Installation instructions vary slightly depending on how you have installed OpenVox:

#### Installing openvox-strings with the [`openvox-agent`](https://docs.openvoxproject.org/openvox/latest/about_agent.html) package

Install the `openvox-strings` gem into the `openvox-agent` environment:

``` bash
sudo /opt/puppetlabs/puppet/bin/gem install openvox-strings
```

#### Installing openvox-strings with the standalone `openvox` gem

Install the `openvox-strings` gem into the same Ruby installation where you have installed the `openvox` gem:

``` bash
gem install openvox-strings
```

### Configure openvox-strings (Optional)

To use YARD options with Strings, specify a `.yardopts` file in the same directory in which you run `puppet strings`.

Strings supports the Markdown format and automatically sets the YARD `markup` option to `markdown`.

To see a list of available YARD options, run `yard help doc`.

For details about YARD options configuration, see the [YARD docs](http://www.rubydoc.info/gems/yard/file/docs/GettingStarted.md#config).

## Generating documentation with openvox-strings

By default, Strings outputs documentation as HTML, or you can specify JSON or Markdown output instead.

Strings generates reference documentation based on the code and Strings code comments in all Puppet and
Ruby source files under the `./manifests/`, `./functions/`, `./lib/`, `./types/`, and `./tasks/` directories.

Strings outputs HTML of the reference information and the module README to the module's `./doc/` directory. This output can be rendered in any browser.

JSON and Markdown output include the reference documentation only.
Strings sends JSON output to either STDOUT or to a file.
Markdown output is written to a REFERENCE.md file in the module's main directory.

See the [OpenVox Strings documentation](https://docs.openvoxproject.org/openvox/latest/openvox_strings.html) for complete instructions for generating documentation with Strings.

For code comment style guidelines and examples, see the [OpenVox Strings style guide](https://docs.openvoxproject.org/openvox/latest/openvox_strings_style.html).

### Additional Resources

Here are a few other good resources for getting started with documentation:

* [Module README Template](https://docs.openvoxproject.org/openvox/latest/modules_documentation.html)
* [YARD Getting Started Guide](http://www.rubydoc.info/gems/yard/file/docs/GettingStarted.md)
* [YARD Tags Overview](http://www.rubydoc.info/gems/yard/file/docs/Tags.md)

## Developing and Contributing

We love contributions from the community!

If you'd like to contribute to `openvox-strings`, check out [CONTRIBUTING.md](https://github.com/voxpupuli/.github/blob/master/CONTRIBUTING.md) to get information on the contribution process.

### Running Specs

If you plan on developing features or fixing bugs in openvox-strings, it is essential that you run specs before opening a pull request.

To run specs, run the `spec` rake task:

``` bash
bundle config set --local path .bundle/gems
bundle install
bundle exec rake spec
```

### Running Acceptance Tests

To run acceptance tests, run the `acceptance` rake task:

``` bash
bundle config set --local path .bundle/gems
bundle install
bundle exec rake acceptance
```

## License

This codebase is licensed under Apache 2.0. However, the open source dependencies included in this codebase might be subject to other software licenses such as AGPL, GPL2.0, and MIT.

## Support

Please log issues in [GitHub issues](https://github.com/voxpupuli/openvox-strings/issues).
Check out [CONTRIBUTING.md](https://github.com/voxpupuli/.github/blob/master/CONTRIBUTING.md) for tips on writing _the best_ issues.

We use semantic version numbers for our releases and recommend that users upgrade to patch releases and minor releases as they become available.

Bug fixes and ongoing development will occur in minor releases for the current major version.
