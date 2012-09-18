module LayoutHelper
  
  # render a single button
  def action_button(label, url, icon = nil, options = {})
    if @in_button_group
      button(label, url, icon, options)
    else
      button_group { button(label, url, icon, options) }
    end
  end
  
  def button_group(&block)
    @in_button_group = true
    html = content_tag(:div, class: 'btn-group', &block)
    @in_button_group = false
    html
  end
  
  def dropdown_button(label, links, icon_name = nil)
    render('shared/dropdown_button', label: label, links: links, icon_name: icon_name)
  end
  
  def icon(name)
    content_tag(:i, '', class: "icon icon-#{name}")
  end
  
  def tab(label, url)
    @tabs ||= []
    @tabs << [label, url]
  end
  
  def render_tabs
    return if @tabs.blank?
    content_tag(:ul, class: 'nav nav-sub') do
      safe_join(@tabs) do |label, url|
        options = {}
        options[:class] = 'active' if current_page?(url)
        content_tag(:li, link_to(label, url), options)
      end
    end
  end
  
  def muted(text)
    content_tag(:span, text, class: 'muted')
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
      [controller.controller_path]
  end
    
  private
  
  def button(label, url, icon_name = nil, options = {})
    add_css_class options, 'btn'
    link_to(url, options) do
      html = [label]
      html.unshift icon(icon_name) if icon_name
      safe_join html, ' '
    end
  end

end
