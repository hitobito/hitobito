# encoding: utf-8
module NavigationHelper

  MAIN = {
          'Gruppen' => {url: :groups_path, 
                        active_for: %w(groups people)},
          'Anlässe' => {url: :list_events_path, 
                        active_for: %w(list_events)},
            'Kurse' => {url: :list_courses_path, 
                        active_for: %w(list_courses)},
            'Admin' => {url: :event_kinds_path, 
                        active_for: %w(event_kinds qualification_kinds custom_contents label_formats), 
                        if: lambda {|_| can?(:manage, Event::Kind) } }
  }
  

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
    if current_page?(url) ||
       active_for.any? {|p| request.path =~ /\/?#{p}\/?/ }
      options[:class] = 'active'
    end
    content_tag(:li, link_to(label, url), options)
  end
  
  def tab_bar(&block)
    bar = TabBar.new(self)
    yield bar
    bar.render
  end
  
end

class TabBar
  
  attr_reader :view
  
  delegate :content_tag, :link_to, :safe_join, :request, :current_page?, to: :view
  
  def initialize(view)
    @view = view
  end
  
    # Create a list item for navigations.
  # If alternative_paths are given, and they appear in the request url,
  # the corresponding item is active.
  # If not alternative paths are given, the item is only active if the link url equals the request url.
  def tab(label, url, alt_paths = [])
    @tabs ||= []
    @tabs << [label, url, alt_paths]
  end
  
  def render
    return if @tabs.blank?
    
    active_url = find_active_tab
    
    content_tag(:ul, class: 'nav nav-sub') do
      safe_join(@tabs) do |label, url, _|
        content_tag(:li, link_to(label, url), class: (url == active_url ? 'active' : nil))
      end
    end
  end

  
  private
  
  # if current_page matches, this tab is active
  # if alt_paths matches, this tab is active
  # if nothing matches, first tab is active
  def find_active_tab
    active = @tabs.detect {|_, url, _| current_page?(url) }
    if active.nil?
      active = @tabs.detect {|_, _, alt_paths| alt_paths.any? {|p| request.path =~ /\/?#{p}\/?/ }}
    end
    active ? active.second : @tabs.first.second
  end
end