require 'yard'

module YARD::Handlers::Capistrano
  class CsetHandler < YARD::Handlers::Ruby::Base #:nodoc:
    handles method_call(:_cset)

    def process
      name = statement.parameters.first.jump(:tstring_content, :ident).source
      value = statement.last.last.source
      log.debug "Handling a cset statement: #{name} = #{value}"
      object = YARD::CodeObjects::ClassVariableObject.new(namespace, name)
      object.value = value
      register(object)
    end
  end
end
