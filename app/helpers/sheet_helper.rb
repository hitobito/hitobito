# Implement a stack based navigation system.
#
# We always place a sheet for the current page on the stack, the previous 
# sheet should return the user to where he came from 
#
# Besides title and link, the sheets also handle fallback links which are
# used when the user is not allow to access the link itself.

module SheetHelper
  
  def sheets
    @sheets ||= Sheet.new(self)
  end
  
  # Get or set the title of the current sheet
  def title(string = nil)
    if string
      sheets.last.title = string
    else
      sheets.last.title
    end
  end
  
  def parent_sheet(sheet)
    @sheets = sheets.prepend(sheet)
  end
  
  def render_sheets(&block)
    sheets.render(&block)
  end
  
end

class Sheet
  attr_accessor :title, :child
  attr_reader :view, :breadcrumbs
  
  delegate :content_tag, :link_to, :safe_join, :capture, :can?, to: :view
  
  def initialize(view, title = nil)
    @view = view
    @title = title
    @breadcrumbs = []
  end
  
  
  def render(&block)
    content = current? ? render_current(&block) : render_parent(&block)
    view.content_tag(:div, content, :class => "sheet #{css_class}")
  end
  
  def last
    child ? child.last : self
  end
  
  def prepend(other)
    other.child = self
    other
  end
  
  private
  
  def render_current(&block)
    content_tag(:div, class: "container-shadow") do
      content_tag(:div, id: "content") do
        render_breadcrumbs +
        render_content(&block)
      end
    end
  end
  
  def render_parent(&block)
    render_breadcrumbs +
    render_title +
    render_content(&block)
  end
  
  def breadcrumbs?
    breadcrumbs.present?
  end

  def render_breadcrumbs
    return "".html_safe unless breadcrumbs?
    
    content_tag(:div, class: 'breadcrumb') do
      content_tag(:ul) do
        safe_join breadcrumbs.collect do |crumb|
          content_tag(:li, crumb + divider)
        end
      end
    end
  end
  
  def render_title
    content_tag(:div, title, class: 'level active')
  end
  
  def render_content(&block)
    if child
      child.render(&block)
    else
      capture(&block)
    end
  end
  
  def divider
    content_tag(:span, '/', class: 'divider')
  end
  
  def css_class
    child ? 'parent' : 'current'
  end
  
  def current?
    child.blank?
  end
  
end

class EntrySheet < Sheet
  attr_reader :entry

  def initialize(view, entry, url_method = nil, can_action = :show, default_url = nil)
    super(view, entry.to_s)
    @entry = entry
    @url_method = Array(url_method)
    @can_action = can_action
    @default_url = default_url
  end
    
  def render_title
    link_to(entry.to_s, link_url(entry), class: 'level active')
  end
  
  def link_url(entry)
    if @url_method.present? && can?(@can_action, entry)
      view.send(*@url_method, entry)
    else
      @default_url || entry
    end
  end
end

class GroupSheet < EntrySheet

  def breadcrumbs
    entry.parent.hierarchy.collect do |g|
      link_to(g.to_s, link_url(g))
    end
  end

  
  def breadcrumbs?
    entry.parent_id?
  end

end

