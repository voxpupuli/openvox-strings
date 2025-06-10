# frozen_string_literal: true

require 'openvox-strings/yard/handlers/helpers'
require 'openvox-strings/yard/handlers/ruby/type_base'
require 'openvox-strings/yard/code_objects'
require 'openvox-strings/yard/util'

# Implements the handler for Puppet resource type newparam/newproperty/ensurable calls written in Ruby.
class OpenvoxStrings::Yard::Handlers::Ruby::TypeExtrasHandler < OpenvoxStrings::Yard::Handlers::Ruby::TypeBase
  # The default docstring when ensurable is used without given a docstring.
  DEFAULT_ENSURABLE_DOCSTRING = 'The basic property that the resource should be in.'

  namespace_only
  handles method_call(:newparam)
  handles method_call(:newproperty)
  handles method_call(:ensurable)

  process do
    # Our entry point is a type newproperty/newparam compound statement like this:
    #  "Puppet::Type.type(:file).newparam(:content) do"
    # We want to
    #  Verify the structure
    #  Capture the three parameters (e.g. type: 'file', newproperty or newparam?, name: 'source')
    #  Proceed with collecting data
    #  Either decorate an existing type object or store for future type object parsing

    # Only accept calls to Puppet::Type.type(<type>).newparam/.newproperty
    # e.g. "Puppet::Type.type(:file).newparam(:content) do" would yield:
    #   module_name:  "Puppet::Type"
    #   method1_name: "type"
    #   typename:     "file"
    #   method2_name: "newparam"
    #   propertyname: "content"

    return unless (statement.count > 1) && (statement[0].children.count > 2)

    module_name = statement[0].children[0].source
    method1_name = statement[0].children.drop(1).find { |c| c.type == :ident }.source
    return unless ['Type', 'Puppet::Type'].include?(module_name) && method1_name == 'type'

    # ensurable is syntatic sugar for newproperty
    typename = get_name(statement[0], 'Puppet::Type.type')
    if caller_method == 'ensurable'
      method2_name = 'newproperty'
      propertyname = 'ensure'
    else
      method2_name = caller_method
      propertyname = get_name(statement, "Puppet::Type.type().#{method2_name}")
    end

    typeobject = get_type_yard_object(typename)

    # node - what should it be here?
    node = statement # ?? not sure... test...

    if method2_name == 'newproperty'
      typeobject.add_property(create_property(propertyname, node))
    elsif method2_name == 'newparam'
      typeobject.add_parameter(create_parameter(propertyname, node))
    end

    # Set the default namevar
    set_default_namevar(typeobject)
  end
end
