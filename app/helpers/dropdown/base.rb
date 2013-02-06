module Dropdown
  class Base
    attr_accessor :template, :label, :main_link, :icon, :button_class
    attr_reader :items
    
    def initialize(template, label, icon = nil)
      @template = template
      @label = label
      @icon = icon
      @main_link = nil
      @button_class = 'btn'
      @items = []
    end
    
    def to_s
      template.render('shared/dropdown_button', 
                      label: label, 
                      items: items, 
                      icon_name: icon, 
                      main_link: main_link, 
                      button_class: button_class)
    end
    
    def divider
      @items << nil
    end
    
    def item(label, url, *sub_items)
      opts = sub_items.extract_options!
      subs = sub_items.collect do |sub_label, sub_url, sub_options|
        if sub_label || sub_url 
          Item.new(sub_label, sub_url, [], sub_options)
        end
      end
      @items << Item.new(label, url, subs, opts)
    end
  end
  
  class Item < Struct.new(:label, :url, :sub_items, :options)
    
    def initialize(label, url, sub_items = [], options = {})
      super(label, url, sub_items, options)
    end
    
    def sub_items?
      sub_items.present?
    end
  end
end