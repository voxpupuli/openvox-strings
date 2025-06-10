# frozen_string_literal: true

require 'openvox-strings/markdown/base'

module OpenvoxStrings::Markdown
  # Generates Markdown for a Puppet Class.
  class PuppetClass < Base
    group_name 'Classes'
    yard_types [:puppet_class]

    def initialize(registry)
      @template = 'classes_and_defines.erb'
      super(registry, 'class')
    end

    def render
      super(@template)
    end
  end
end
