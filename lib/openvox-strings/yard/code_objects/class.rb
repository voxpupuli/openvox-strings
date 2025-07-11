# frozen_string_literal: true

require 'openvox-strings/yard/code_objects/group'

# Implements the group for Puppet classes.
class OpenvoxStrings::Yard::CodeObjects::Classes < OpenvoxStrings::Yard::CodeObjects::Group
  # Gets the singleton instance of the group.
  # @return Returns the singleton instance of the group.
  def self.instance
    super(:puppet_classes)
  end

  # Gets the display name of the group.
  # @param [Boolean] prefix whether to show a prefix. Ignored for Puppet group namespaces.
  # @return [String] Returns the display name of the group.
  def name(_prefix = false)
    'Puppet Classes'
  end
end

# Implements the Puppet class code object.
class OpenvoxStrings::Yard::CodeObjects::Class < OpenvoxStrings::Yard::CodeObjects::Base
  attr_reader :statement, :parameters

  # Initializes a Puppet class code object.
  # @param [OpenvoxStrings::Parsers::ClassStatement] statement The class statement that was parsed.
  # @return [void]
  def initialize(statement)
    @statement = statement
    @parameters = statement.parameters.map { |p| [p.name, p.value] }
    super(OpenvoxStrings::Yard::CodeObjects::Classes.instance, statement.name)
  end

  # Gets the type of the code object.
  # @return Returns the type of the code object.
  def type
    :puppet_class
  end

  # Gets the source of the code object.
  # @return Returns the source of the code object.
  def source
    @statement.source
  end

  # Converts the code object to a hash representation.
  # @return [Hash] Returns a hash representation of the code object.
  def to_hash
    hash = {}
    hash[:name] = name
    hash[:file] = file
    hash[:line] = line
    hash[:inherits] = statement.parent_class if statement.parent_class
    hash[:docstring] = OpenvoxStrings::Yard::Util.docstring_to_hash(docstring)
    defaults = Hash[*parameters.reject { |p| p[1].nil? }.flatten]
    hash[:defaults] = defaults unless defaults.nil? || defaults.empty?
    hash[:source] = source unless source.nil? || source.empty?
    hash
  end
end
