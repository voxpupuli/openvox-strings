# frozen_string_literal: true

require 'yaml'

module OpenvoxStrings
  # Parser for Hiera configuration and data
  class Hiera
    attr_reader :hiera_config, :common_data

    # Initializes a Hiera parser for a given module path
    # @param [String] module_path The path to the Puppet module root directory
    def initialize(module_path)
      @module_path = module_path
      @hiera_config = load_hiera_config
      @common_data = load_common_data
    end

    # Checks if Hiera is configured for this module
    # @return [Boolean] true if hiera.yaml exists and is valid
    def hiera_enabled?
      !@hiera_config.nil?
    end

    # Gets the default value for a parameter from Hiera data
    # @param [String] class_name The fully qualified class name (e.g., 'github_actions_runner')
    # @param [String] param_name The parameter name
    # @return [String, nil] The default value as a string, or nil if not found
    def lookup_default(class_name, param_name)
      return nil unless hiera_enabled?
      return nil if @common_data.nil?

      # Try to lookup with class prefix: modulename::parametername
      key = "#{class_name}::#{param_name}"
      return nil unless @common_data.key?(key)

      value = @common_data[key]

      # Convert value to Puppet-compatible string representation
      value_to_puppet_string(value)
    end

    private

    # Loads and parses hiera.yaml from the module root
    # @return [Hash, nil] The parsed hiera configuration, or nil if not found/invalid
    def load_hiera_config
      hiera_file = File.join(@module_path, 'hiera.yaml')
      load_yaml_data(hiera_file)
    end

    # Finds the path to the first static hierarchy layer (without interpolations)
    # @return [String, nil] The full path to the data file, or nil if not found
    def find_first_static_layer_path
      return nil unless hiera_enabled?

      # Get datadir from hiera config (defaults to 'data')
      datadir = @hiera_config.dig('defaults', 'datadir') || 'data'

      # Find first hierarchy entry without interpolations
      hierarchy = @hiera_config['hierarchy']
      return nil unless hierarchy

      first_static = hierarchy.find do |entry|
        path_or_paths = entry['path'] || entry['paths']
        next false unless path_or_paths

        # Check if path(s) contain interpolations like %{...}
        case path_or_paths
        when String
          !path_or_paths.include?('%{')
        when Array
          path_or_paths.none? { |p| p.include?('%{') }
        else
          false
        end
      end

      return nil unless first_static

      # Get the path from the hierarchy entry
      data_file_path = first_static['path'] || first_static['paths']&.first
      return nil unless data_file_path

      # Build and return full path
      File.join(@module_path, datadir, data_file_path)
    end

    # Loads and parses a YAML data file
    # @param [String] file_path The full path to the YAML file to load
    # @return [Hash, nil] The parsed YAML data, or nil if not found/invalid
    def load_yaml_data(file_path)
      return nil unless File.exist?(file_path)

      begin
        YAML.load_file(file_path)
      rescue StandardError => e
        YARD::Logger.instance.warn "Failed to parse #{File.basename(file_path)}: #{e.message}"
        nil
      end
    end

    # Loads and parses the first static hierarchy layer (without interpolations)
    # @return [Hash, nil] The parsed data, or nil if not found/invalid
    def load_common_data
      data_file = find_first_static_layer_path
      return nil unless data_file

      load_yaml_data(data_file)
    end

    # Converts a Ruby value to a Puppet-compatible string representation
    # @param [Object] value The value to convert
    # @return [String] The Puppet-compatible string representation
    def value_to_puppet_string(value)
      case value
      when String
        # Empty strings from YAML nil (~) should be undef
        return 'undef' if value.empty?

        # Strings should be quoted
        "'#{value}'"
      when Integer, Float, TrueClass, FalseClass
        # Numbers and booleans are unquoted/lowercase
        value.to_s
      when NilClass, :undef
        # Puppet undef
        'undef'
      when Hash
        # Convert hash to Puppet hash syntax (no spaces to match code defaults format)
        return '{}' if value.empty?

        pairs = value.map { |k, v| "'#{k}' => #{value_to_puppet_string(v)}" }
        "{ #{pairs.join(', ')} }"
      when Array
        # Convert array to Puppet array syntax (no spaces to match code defaults format)
        return '[]' if value.empty?

        elements = value.map { |v| value_to_puppet_string(v) }
        "[#{elements.join(', ')}]"
      else
        # Fallback: convert to string and quote
        "'#{value}'"
      end
    end
  end
end
