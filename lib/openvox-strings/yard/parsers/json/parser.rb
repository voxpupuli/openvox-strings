# frozen_string_literal: true

require 'openvox-strings/yard/parsers/json/task_statement'

# Implementas a JSON parser.
class OpenvoxStrings::Yard::Parsers::JSON::Parser < YARD::Parser::Base
  attr_reader :file, :source

  # Initializes the parser.
  # @param [String] source The source being parsed.
  # @param [String] filename The file name of the file being parsed.
  # @return [void]
  def initialize(source, filename) # rubocop:disable Lint/MissingSuper
    @file = filename
    @source = source
    @statements = []
  end

  def enumerator
    @statements
  end

  # Parses the source
  # @return [void]
  def parse
    begin
      json = JSON.parse(source)
      # TODO: this should compare json to a Task metadata json-schema or perform some other hueristics
      # to determine what type of statement it represents
      @statements.push(OpenvoxStrings::Yard::Parsers::JSON::TaskStatement.new(json, @source, @file)) unless json.empty?
    rescue StandardError
      log.error "Failed to parse #{@file}: "
      @statements = []
    end
    @statements.freeze
    self
  end
end
