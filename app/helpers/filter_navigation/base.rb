module FilterNavigation
  class Base
    
    attr_reader :template, :main_items, :dropdown_links, :dropdown_label, :dropdown_active, :active_label
    
    delegate :content_tag, :link_to, to: :template
    
    def initialize(template)
      @template = template
      @main_items = []
      @dropdown_links = []
      @active_label = nil
      @dropdown_label = 'Weitere Ansichten'
      @dropdown_active = false
    end
    
    
    def to_s
      content_tag(:div, class: 'toolbar-pills') do
        content_tag(:ul, class: 'nav nav-pills group-pills') do
          items = main_items
          if dropdown_links.present?
            items << dropdown
          end
          template.safe_join(items)
        end
      end
    end

    private
    
    def item(label, url)
      @main_items << content_tag(:li, link_to(label, url), class: ('active' if active_label == label))
    end
    
    def dropdown_link(link)
      @dropdown_links << link
    end
    
    def dropdown
      content_tag(:li, class: "dropdown #{'active' if dropdown_active}") do
        template.in_button_group do
          template.dropdown_button(dropdown_label, dropdown_links, nil, nil, nil)
        end
      end
    end
  
  end
  
end