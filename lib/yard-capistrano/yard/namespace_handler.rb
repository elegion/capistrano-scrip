require 'yard'

module YARD::Handlers::Capistrano
  class NamespaceHandler < YARD::Handlers::Ruby::Base
    handles method_call(:namespace)

    def process
      parse_block(statement.last.last)
      return
      name = statement.parameters.first.jump(:tstring_content, :ident).source
      log.debug "Handling a namespace statement: #{name}"
      object = YARD::CodeObjects::ClassObject.new(namespace, name)
      register(object)
      parse_block(statement.last.last, namespace: object)
    end
  end
end
