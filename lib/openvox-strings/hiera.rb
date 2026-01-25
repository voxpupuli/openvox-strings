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
      return nil unless File.exist?(hiera_file)

      begin
        YAML.load_file(hiera_file)
      rescue StandardError => e
        YARD::Logger.instance.warn "Failed to parse hiera.yaml: #{e.message}"
        nil
      end
    end

    # Loads and parses data/common.yaml from the module
    # @return [Hash, nil] The parsed common data, or nil if not found/invalid
    def load_common_data
      return nil unless hiera_enabled?

      # Get datadir from hiera config (defaults to 'data')
      datadir = @hiera_config.dig('defaults', 'datadir') || 'data'
      common_file = File.join(@module_path, datadir, 'common.yaml')

      return nil unless File.exist?(common_file)

      begin
        YAML.load_file(common_file)
      rescue StandardError => e
        YARD::Logger.instance.warn "Failed to parse common.yaml: #{e.message}"
        nil
      end
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
      when Integer, Float
        # Numbers are unquoted
        value.to_s
      when TrueClass, FalseClass
        # Booleans are lowercase
        value.to_s
      when NilClass, :undef
        # Puppet undef
        'undef'
      when Hash
        # Convert hash to Puppet hash syntax
        return '{}' if value.empty?

        pairs = value.map { |k, v| "'#{k}' => #{value_to_puppet_string(v)}" }
        "{ #{pairs.join(', ')} }"
      when Array
        # Convert array to Puppet array syntax
        return '[]' if value.empty?

        elements = value.map { |v| value_to_puppet_string(v) }
        "[ #{elements.join(', ')} ]"
      else
        # Fallback: convert to string and quote
        "'#{value}'"
      end
    end
  end
end
