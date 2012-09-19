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
  
  delegate :content_tag, :link_to, :safe_join, :capture, to: :view
  
  def initialize(view)
    @view = view
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

class GroupSheet < Sheet
  
  attr_reader :group
  
  def initialize(view, group, url_method = nil)
    super(view)
    @group = group
    @url_method = url_method
    self.title = group.to_s
  end
  
  def breadcrumbs
    group.parent.hierarchy.collect do |g|
      link_to g, link_url(g)
    end
  end
  
  def breadcrumbs?
    group.parent_id?
  end
      
  def render_title
    link_to(group.to_s, link_url(group), class: 'level active')
  end
  
  def link_url(group)
    if @url_method
      view.send(@url_method, group)
    else
      group
    end
  end
end