include Helpers::ModuleHelper

# Generate a searchable class list in the output
def generate_class_list
  @items = options.objects if options.objects
  @list_title = "Recipes List"
  @list_type = "class"
  generate_list_contents
end
