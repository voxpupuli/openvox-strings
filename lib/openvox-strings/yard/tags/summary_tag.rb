# frozen_string_literal: true

# Implements a summary tag for general purpose short descriptions
class OpenvoxStrings::Yard::Tags::SummaryTag < YARD::Tags::Tag
  # Registers the tag with YARD.
  # @return [void]
  def self.register!
    YARD::Tags::Library.define_tag('puppet.summary', :summary)
  end
end
