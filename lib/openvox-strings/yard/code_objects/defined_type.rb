# frozen_string_literal: true

require 'openvox-strings/yard/code_objects/group'

# Implements the group for Puppet defined types.
class OpenvoxStrings::Yard::CodeObjects::DefinedTypes < OpenvoxStrings::Yard::CodeObjects::Group
  # Gets the singleton instance of the group.
  # @return Returns the singleton instance of the group.
  def self.instance
    super(:puppet_defined_types)
  end

  # Gets the display name of the group.
  # @param [Boolean] prefix whether to show a prefix. Ignored for Puppet group namespaces.
  # @return [String] Returns the display name of the group.
  def name(_prefix = false)
    'Defined Types'
  end
end

# Implements the Puppet defined type code object.
class OpenvoxStrings::Yard::CodeObjects::DefinedType < OpenvoxStrings::Yard::CodeObjects::Base
  attr_reader :statement, :parameters

  # Initializes a Puppet defined type code object.
  # @param [OpenvoxStrings::Parsers::DefinedTypeStatement] statement The defined type statement that was parsed.
  # @return [void]
  def initialize(statement)
    @statement = statement
    @parameters = statement.parameters.map { |p| [p.name, p.value] }
    super(OpenvoxStrings::Yard::CodeObjects::DefinedTypes.instance, statement.name)
  end

  # Gets the type of the code object.
  # @return Returns the type of the code object.
  def type
    :puppet_defined_type
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
    hash[:docstring] = OpenvoxStrings::Yard::Util.docstring_to_hash(docstring)
    defaults = Hash[*parameters.reject { |p| p[1].nil? }.flatten]
    hash[:defaults] = defaults unless defaults.nil? || defaults.empty?
    hash[:source] = source unless source.nil? || source.empty?
    hash
  end
end
