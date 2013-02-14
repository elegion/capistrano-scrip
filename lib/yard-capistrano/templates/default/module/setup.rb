include Helpers::ModuleHelper

def init
  sections :header, :pre_docstring, T('docstring'),
           :constant_summary, [T('docstring')], :inherited_constants,
           :attribute_summary, [:item_summary], :inherited_attributes,
           :method_summary, [:item_summary], :inherited_methods,
           :methodmissing, [T('method_details')],
           :attribute_details, [T('method_details')],
           :method_details_list, [T('method_details')]

  def task_signature(meth, link = true, show_extras = true, full_attr_name = true)
      title = "#{meth.namespace.name}:#{meth.name}"
      meth = convert_method_to_overload(meth)
      obj = meth.respond_to?(:object) ? meth.object : meth
      url = url_for(object, obj)
      if link
        link_url(url, title, :title => title)
      else
        title
      end
  end
end
