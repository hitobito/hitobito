module LayoutHelper
  
  # render a single button
  def action_button(label, url, icon = nil, options = {})
    if @in_button_group || options[:in_button_group]
      button(label, url, icon, options)
    else
      button_group { button(label, url, icon, options) }
    end
  end
  
  def button_group(&block)
    if @in_button_group
      capture(&block)
    else
      @in_button_group = true
      html = content_tag(:div, class: 'btn-group', &block)
      @in_button_group = false
      html
    end
  end
  
  def dropdown_button(label, links, icon_name = nil, main_link = nil, button_class = 'btn')
    render('shared/dropdown_button', 
           label: label, 
           links: links, 
           icon_name: icon_name, 
           main_link: main_link, 
           button_class: button_class)
  end

  def pill_dropdown_button(label, links, css_classes = 'pull-right')
    content_tag(:ul, class: "nav nav-pills #{css_classes}") do
      content_tag(:li, class: 'dropdown') do
        @in_button_group = true
        html = dropdown_button(label, links, nil, nil, nil)
        @in_button_group = false
        html
      end
    end
  end
  
  def icon(name)
    content_tag(:i, '', class: "icon icon-#{name}")
  end
  
  
  def section(title, &block)
    render(layout: 'shared/section', locals: {title: title}, &block)
  end
  
  def section_table(title, collection, add_path = nil, &block)
    collection.inspect # force relation evaluation
    if add_path || collection.present?
      if add_path
        title = safe_join([title,
                           content_tag(:span, 
                                       button_action_add(add_path, nil, class: 'btn-small'), 
                                       class: 'pull-right')])
      end
      render(layout: 'shared/section_table', 
             locals: {title: title, collection: collection, add_path: add_path}, 
             &block)
    end 
  end
  
  def grouped_table(grouped_lists, column_count, &block)
    render(layout: 'shared/grouped_table',
           locals: {grouped_lists: grouped_lists, column_count: column_count},
           &block)
  end
  
  def muted(text = nil, &block)
    content_tag(:span, text, class: 'muted', &block)
  end
  
  def value_with_muted(value, mute)
    safe_join([f(value), muted(mute)], ' ')
  end
  
  # Renders all partials with names that match "_#{key}_*.html.haml"
  # in alphabetical order.
  def render_extensions(key, options = {})
    safe_join(find_extensions(key, options.delete(:folder))) do |e|
      render options.merge(:partial => e) 
    end
  end        
  
  def find_extensions(key, folder = nil)
      folders = extension_folders
      folders << folder if folder
      extensions = folders.collect do |f|
          view_paths.collect do |path|
              Dir.glob(File.join(path, f, "_#{key}_*.html.haml"))
          end
      end
      extensions = extensions.flatten.sort_by { |f| File.basename(f) }
      extensions.collect do |f|
          m = f.match(/views.(.+?[\/\\])_(.+).html.haml/)
          m[1] + m[2]
      end
  end
  
  def extension_folders
    [@virtual_path[/(.+)\/.*/, 1]]
  end
    
  private
  
  def button(label, url, icon_name = nil, options = {})
    add_css_class options, 'btn'
    link_to(url, options) do
      html = [label]
      html.unshift icon(icon_name) if icon_name
      safe_join(html, ' ')
    end
  end

end
