# Extension of StandardHelper functionality to provide a set of default
# attributes for the current model to be used in tables and forms. This helper
# is included in CrudController.
module CrudHelper

  # Render a generic form for the current entry
  def entry_form(*attrs, &block)
    options = attrs.extract_options!
    options[:buttons_bottom] = true unless options.has_key?(:buttons_bottom)
    attrs = attrs_or_default(attrs) { default_attrs - [:created_at, :updated_at] }
    crud_form(path_args(entry), *attrs, options, &block)
  end

  # Renders a generic form for the current entry with :default_attrs or the
  # given attribute array, using the StandardFormBuilder. An options hash
  # may be given as the last argument.
  # If a block is given, a custom form may be rendered and attrs is ignored.
  def crud_form(object, *attrs, &block)
    options = attrs.extract_options!
    
    buttons_bottom = options.delete(:buttons_bottom)
    submit_label = options.delete(:submit_label) || ti(:"button.save")
    cancel_url = options.delete(Array(object).last.new_record? ? :cancel_url_new : :cancel_url_edit)
    cancel_url ||= polymorphic_path(object, :returning => true)

    standard_form(object, options) do |form|
      content = save_form_buttons(form, submit_label, cancel_url)
      
      content << form.error_messages
      
      content << if block_given?
        capture(form, &block)
      else
        form.labeled_input_fields(*attrs)
      end
      
      content <<  save_form_buttons(form, submit_label, cancel_url) if buttons_bottom
      
      content.html_safe
    end
  end
  
  def save_form_buttons(form, submit_label, cancel_url)
   content_tag(:div, class: 'btn-toolbar') do
      submit_button(form, submit_label) +
      content_tag(:div, class: 'btn-group') do
        link_to(ti(:"button.cancel"), cancel_url, :class => 'btn')
      end
    end
  end
  
  def submit_button(form, label)
    content_tag(:div, class: 'btn-group') do
      form.button(label, :class => 'btn btn-primary')
    end
  end

  # Create a table of the entries with the default or
  # the passed attributes in its columns. An options hash may be given
  # as the last argument.
  def crud_table(*attrs, &block)
    if block_given?
      list_table(*attrs, &block)
    else
      attrs = attrs_or_default(attrs) { default_attrs }
      list_table(*attrs) do |t|
         add_table_actions(t)
      end
    end
  end

  # Adds a set of standard action link column (show, edit, destroy) to the given table.
  def add_table_actions(table)
    action_col_show(table)
    action_col_edit(table)
    action_col_destroy(table)
  end

  # Action link to show the row entry inside a table.
  # A block may be given to define the link path for the row entry.
  def action_col_show(table, &block)
    action_col(table) { |e| link_table_action('zoom-in', action_path(e, &block)) }
  end

  # Action link to edit inside a table.
  # A block may be given to define the link path for the row entry.
  def action_col_edit(table, &block)
    action_col(table) do |e|
      path = action_path(e, &block)
      link_table_action('edit', path.is_a?(String) ? path : edit_polymorphic_path(path))
    end
  end

  # Action link to destroy inside a table.
  # A block may be given to define the link path for the row entry.
  def action_col_destroy(table, &block)
    action_col(table) do |e|
      link_table_action('trash', action_path(e, &block),
                        :data => { :confirm => ti(:confirm_delete),
                                   :method => :delete })
    end
  end

  # Generic action link inside a table.
  def link_table_action(icon, url, html_options = {})
    add_css_class html_options, "icon-#{icon}"
    link_to('', url, html_options)
  end

  # Defines a column with an action link.
  def action_col(table, &block)
    table.col('', :class => 'action', &block)
  end

  ######## ACTION LINKS ###################################################### :nodoc:

  # Standard link action to the show page of a given record.
  # Uses the current record if none is given.
  def link_action_show(path = nil)
    path ||= path_args(entry)
    action_button ti(:"link.show"), path, 'zoom-in'
  end

  # Standard link action to the edit page of a given record.
  # Uses the current record if none is given.
  def link_action_edit(path = nil)
    path ||= path_args(entry)
    action_button ti(:"link.edit"), path.is_a?(String) ? path : edit_polymorphic_path(path), 'edit'
  end

  # Standard link action to the destroy action of a given record.
  # Uses the current record if none is given.
  def link_action_destroy(path = nil)
    path ||= path_args(entry)
    action_button ti(:"link.delete"), path, 'trash',
                :data => { :confirm => ti(:confirm_delete),
                           :method => :delete }
  end

  # Standard link action to the list page.
  # Links to the current model_class if no path is given.
  def link_action_index(path = nil, url_options = {:returning => true})
    path ||= path_args(model_class)
    action_button ti(:"link.list"), path.is_a?(String) ? path : polymorphic_path(path, url_options), 'list'
  end

  # Standard link action to the new page.
  # Links to the current model_class if no path is given.
  def link_action_add(path = nil, url_options = {})
    path ||= path_args(model_class)
    action_button ti(:"link.add"), path.is_a?(String) ? path : new_polymorphic_path(path, url_options), 'plus'
  end

  private

  # If a block is given, call it to get the path for the current row entry.
  # Otherwise, return the standard path args.
  def action_path(e, &block)
    block_given? ? yield(e) : path_args(e)
  end

  # Returns default attrs for a crud table if no others are passed.
  def attrs_or_default(attrs)
    options = attrs.extract_options!
    attrs = yield if attrs.blank?
    attrs << options
  end

end
