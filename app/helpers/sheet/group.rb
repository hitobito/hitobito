# encoding: utf-8
module Sheet
  class Group < Base
    self.has_tabs = true
    
    delegate :group_path, to: :view
    
    def render_breadcrumbs
      return "".html_safe unless breadcrumbs?
      
      content_tag(:div, class: 'breadcrumb') do
        content_tag(:ul) do
          crumbs = breadcrumbs.reverse.collect do |crumb|
            content_tag(:li, crumb)
          end
          
          content_tag(:li, 'geh&ouml;rt zu ') +
          StandardHelper::EMPTY_STRING + 
          safe_join(crumbs, divider)
        end
      end
    end
    
    private
    
    def link_url
      group_path(entry.id)
    end
    
    def breadcrumbs
      entry.parent.hierarchy.collect do |g|
        link_to(g.to_s, group_path(g))
      end
    end
    
    def divider
      content_tag(:span, '>', class: 'divider')
    end
    
    def breadcrumbs?
      entry.parent_id?
    end

  end
end