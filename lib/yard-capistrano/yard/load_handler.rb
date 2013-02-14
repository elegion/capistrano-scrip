require 'yard'

module YARD::Handlers::Capistrano
  class LoadHandler < YARD::Handlers::Ruby::Base
    handles method_call(:load)

    def process
      #puts "Handling a load statement!"
      #return parse_block(statement.last.last)

      name = parser.file.to_s

      ns = namespace
      name.sub!(/^lib\/capistrano-scrip\//, '').sub!(/\.rb$/, '').split('/').each { |part|
        ns = YARD::CodeObjects::ModuleObject.new(ns, part)
        register(ns)
      }

      #name.sub!(/^lib\//, '').sub!(/\.rb$/, '')
      #object = YARD::CodeObjects::ModuleObject.new(namespace, name)
      #register(object)
      #ns = object

      log.debug "Handling a load statement: #{name}"
      parse_block(statement.last.last, namespace: ns)
    end
  end
end
