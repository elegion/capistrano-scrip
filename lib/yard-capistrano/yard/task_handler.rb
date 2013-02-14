require 'yard'

module YARD::Handlers::Capistrano
  class TaskHandler < YARD::Handlers::Ruby::Base
    handles method_call(:task)
    handles method_call(:host_task)

    def process
      name = statement.parameters.first.jump(:tstring_content, :ident).source
      log.debug "Handling task statement: #{name} (under namespace #{namespace})"
      object = YARD::CodeObjects::MethodObject.new(namespace, name, :class)
      if parser.extra_state.desc
        object.docstring = parser.extra_state.desc
        parser.extra_state.delete_field(:desc)
      end
      register(object)
    end
  end
end
