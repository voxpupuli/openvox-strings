# frozen_string_literal: true

require 'openvox-strings/markdown/base'

module OpenvoxStrings::Markdown
  # Generates Markdown for a Puppet resource type provider.
  class Provider < Base
    group_name 'Providers'
    yard_types [:puppet_provider]

    def initialize(registry)
      @template = 'provider.erb'
      super(registry, 'provider')
    end

    def render
      super(@template)
    end

    # @return [String] the name of the resource type the provider implements
    def type_name
      @registry[:type_name]&.to_s
    end

    # @return [Hash] the provider's confines
    def confines
      @registry[:confines]
    end

    # @return [Array] the provider's features
    def features
      @registry[:features]
    end

    # Unlike other components, a provider's defaults are `defaultfor`
    # constraints (an Array of key-value pair Arrays), not parameter
    # defaults, so Hiera data must not be merged in.
    #
    # @return [Array] the provider's defaultfor constraints
    def defaults
      @registry[:defaults]
    end

    # @return [Hash] the provider's commands
    def commands
      @registry[:commands]
    end

    # Providers of different resource types may share a name, so include the
    # type name in the anchor link.
    #
    # @return [String] the component's markdown link
    def link
      clean_link("provider_#{type_name}_#{name}")
    end
  end
end
