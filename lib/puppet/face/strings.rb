# frozen_string_literal: true

require 'puppet/face'

# Implements the 'puppet strings' interface.
Puppet::Face.define(:strings, '0.0.1') do # rubocop:disable Metrics/BlockLength
  summary 'Generate Puppet module documentation with YARD.'

  action(:generate) do
    default

    option '--format OUTPUT_FORMAT' do
      summary 'Designate output format, JSON or markdown.'
    end
    option '--out PATH' do
      summary 'Write selected format to PATH. If no path is designated, strings prints to STDOUT.'
    end
    option '--markup FORMAT' do
      summary "The markup format to use for docstring text (defaults to 'markdown')."
    end

    summary 'Generate documentation from files.'
    arguments '[[search_pattern] ...]'

    when_invoked do |*args|
      check_required_features
      require 'openvox-strings'

      OpenvoxStrings.generate(
        args.count > 1 ? args[0..-2] : OpenvoxStrings::DEFAULT_SEARCH_PATTERNS,
        build_generate_options(args.last)
      )
      nil
    end
  end

  action(:server) do
    option '--markup FORMAT' do
      summary "The markup format to use for docstring text (defaults to 'markdown')."
    end

    summary 'Runs a local documentation server for the modules in the current Puppet environment.'
    arguments '[[module_name] ...]'

    when_invoked do |*args|
      check_required_features
      require 'openvox-strings'

      modules = args.count > 1 ? args[0..-2] : []

      # Generate documentation for all (or the given) modules
      module_docs = []
      environment = Puppet.lookup(:current_environment)
      environment.modules.each do |mod|
        next unless modules.empty? || modules.include?(mod.name)

        db = File.join(mod.path, '.yardoc')
        patterns = OpenvoxStrings::DEFAULT_SEARCH_PATTERNS.map do |p|
          File.join(mod.path, p)
        end
        puts "Generating documentation for Puppet module '#{mod.name}'."
        OpenvoxStrings.generate(patterns, build_generate_options(args.last, '--db', db))

        # Clear the registry so that the next call to generate has a clean database
        YARD::Registry.clear

        module_docs << mod.name
        module_docs << db
      end

      if module_docs.empty?
        puts 'No Puppet modules were found to serve documentation for.'
        return
      end
      puts 'Starting YARD documentation server.'
      OpenvoxStrings.run_server('-m', *module_docs)
      nil
    end
  end

  action(:describe) do # This is Kris' experiment with string based describe
    option '--list' do
      summary 'list types'
    end
    option '--providers' do
      summary 'provide details on providers for each type'
    end
    option '--list-providers' do
      summary 'list all providers'
    end

    # TODO: Implement the rest of describe behavior
    #     * --help:
    #   Print this help text

    # * --providers:
    #   Describe providers in detail for each type

    # * --list:
    #   List all types

    # * --list-providers:
    #   list all providers

    # * --meta:
    #   List all metaparameters

    # * --short:
    #   List only parameters without detail

    when_invoked do |*args|
      check_required_features
      require 'openvox-strings'

      options = args.last
      options[:describe] = true
      options[:stdout] = true
      options[:format] = 'json'

      if args.length > 1
        if options[:list]
          warn 'WARNING: ignoring types when listing all types.'
        else
          options[:describe_types] = args[0..-2]
        end
      end

      # TODO: Set up search_patterns and whatever else needed to collect data for describe - currently missing some
      #          manifests/**/*.pp
      #          functions/**/*.pp
      #          tasks/*.json
      #          plans/*.pp
      search_patterns = ['types/**/*.pp', 'lib/**/*.rb']
      OpenvoxStrings.generate(
        search_patterns,
        build_generate_options(options)
      )
      nil
    end
  end

  # Checks that the required features are installed.
  # @return [void]
  def check_required_features
    raise "The 'yard' gem must be installed in order to use this face." unless Puppet.features.yard?
    raise "The 'rgen' gem must be installed in order to use this face." unless Puppet.features.rgen?
  end

  # Builds the options to OpenvoxStrings.generate.
  # @param [Hash] options The Puppet face options hash.
  # @param [Array] yard_args The additional arguments to pass to YARD.
  # @return [Hash] Returns the OpenvoxStrings.generate options hash.
  def build_generate_options(options = nil, *yard_args)
    generate_options = {}
    generate_options[:debug] = Puppet[:debug]
    generate_options[:backtrace] = Puppet[:trace]
    generate_options[:yard_args] = yard_args unless yard_args.empty?
    if options
      markup = options[:markup]
      generate_options[:markup] = markup if markup
      generate_options[:path] = options[:out] if options[:out]
      generate_options[:stdout] = options[:stdout]

      if options[:describe]
        generate_options[:describe] = true
        generate_options[:describe_types] = options[:describe_types]
        generate_options[:describe_list] = options[:list]
        generate_options[:providers] = options[:providers]
        generate_options[:list_providers] = options[:list_providers]
      end

      format = options[:format]
      if format
        if format.casecmp('markdown').zero?
          generate_options[:markdown] = true
        elsif format.casecmp('json').zero?
          generate_options[:json] = true
        else
          raise "Invalid format #{options[:format]}. Please select 'json' or 'markdown'."
        end
      end
    end
    generate_options
  end
end
