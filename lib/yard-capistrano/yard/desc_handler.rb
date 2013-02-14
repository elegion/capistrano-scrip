require 'yard'

module YARD::Handlers::Capistrano
  class DescHandler < YARD::Handlers::Ruby::Base
    handles method_call(:desc)

    def process
      def unindent(str)
        indent = str.split("\n").select {|line| !line.strip.empty? }.map {|line| line.index(/[\S]/) }.compact.min || 0
        str.gsub(/^[[:blank:]]{#{indent}}/, '')
      end
      s = statement
      p = statement.parameters
      n = statement.parameters.first.jump(:tstring_content, :ident).source
      text = if statement.parameters.first.length > 1
        statement.parameters.first.map{|p| p.jump(:tstring_content, :ident).source if p}.join('')
      else
        statement.parameters.first.jump(:tstring_content, :ident).source
      end

      heredoc_match = /^<<-(\w+)/.match(text)
      if heredoc_match
        text = unindent text.gsub(/^<<-#{heredoc_match[1]}.*\n/, '').sub(/\s+#{heredoc_match[1]}$/m, '')
        text.gsub!(/\\\n/, '')
      end
      parser.extra_state.desc = text
    end
  end
end
