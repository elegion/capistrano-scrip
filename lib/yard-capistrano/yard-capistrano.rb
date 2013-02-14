require File.dirname(__FILE__) + '/yard/load_handler'
require File.dirname(__FILE__) + '/yard/namespace_handler'
require File.dirname(__FILE__) + '/yard/cset_handler'
require File.dirname(__FILE__) + '/yard/task_handler'
require File.dirname(__FILE__) + '/yard/desc_handler'

YARD::Templates::Engine.register_template_path File.dirname(__FILE__) + '/templates'
