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
    @in_button_group = true
    html = content_tag(:div, class: 'btn-group', &block)
    @in_button_group = false
    html
  end
  
  def dropdown_button(label, links, icon_name = nil, main_link = nil)
    render('shared/dropdown_button', label: label, links: links, icon_name: icon_name, main_link: main_link)
  end
  
  def icon(name)
    content_tag(:i, '', class: "icon icon-#{name}")
  end
  
  def tab(label, url, alt_paths = [])
    @tabs ||= []
    @tabs << [label, url, alt_paths]
  end

  def render_tabs
    return if @tabs.blank?
    content_tag(:ul, class: 'nav nav-sub') do
      safe_join(@tabs) { |label, url, alt_paths| nav(label, url, alt_paths) }
    end
  end
    
  # Create a list item for navigations.
  # If alternative_paths are given, and they appear in the request url,
  # the corresponding item is active.
  # If not alternative paths are given, the item is only active if the link url equals the request url.
  def nav(label, url, alternative_paths = [])
    options = {}
    if (alternative_paths.blank? && current_page?(url)) ||
       alternative_paths.any? {|p| request.path =~ /\/#{p}\/?/ }
      options[:class] = 'active'
    end
    content_tag(:li, link_to(label, url), options)
  end
  
  def muted(text)
    content_tag(:span, text, class: 'muted')
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
      [controller.controller_path]
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
