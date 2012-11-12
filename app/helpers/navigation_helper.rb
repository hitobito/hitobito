# encoding: utf-8
module NavigationHelper

  MAIN = {
          'Gruppen' => {url: :groups_path, 
                        active_for: %w(groups people)},
    'Kurse/Anlässe' => {url: :list_courses_path, 
                        active_for: %w(list_courses list_events)},
            'Admin' => {url: :event_kinds_path, 
                        active_for: %w(event_kinds qualification_kinds), 
                        if: lambda {|_| can?(:manage, Event::Kind) } }
  }
  
  
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
    
  def render_main_nav
    content_tag_nested(:ul, MAIN, class: 'nav') do |label, options|
      if options[:url].kind_of?(Symbol)
        options[:url] = send(options[:url])
      end
      if !options.has_key?(:if) || instance_eval(&options[:if])
        nav(label, options[:url], options[:active_for])
      end
    end
  end
    
  # Create a list item for navigations.
  # If alternative_paths are given, and they appear in the request url,
  # the corresponding item is active.
  # If not alternative paths are given, the item is only active if the link url equals the request url.
  def nav(label, url, active_for = [])
    options = {}
    if (active_for.blank? && current_page?(url)) ||
       active_for.any? {|p| request.path =~ /\/#{p}\/?/ }
      options[:class] = 'active'
    end
    content_tag(:li, link_to(label, url), options)
  end
  
end