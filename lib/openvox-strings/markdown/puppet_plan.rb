# frozen_string_literal: true

require 'openvox-strings/markdown/base'

module OpenvoxStrings::Markdown
  # Generates Markdown for a Puppet Plan.
  class PuppetPlan < Base
    group_name 'Plans'
    yard_types [:puppet_plan]

    def initialize(registry)
      @template = 'classes_and_defines.erb'
      super(registry, 'plan')
    end

    def render
      super(@template)
    end
  end
end
