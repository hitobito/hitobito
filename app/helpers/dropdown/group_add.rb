# encoding: utf-8
module Dropdown
  class GroupAdd < Base
    
    attr_reader :group
    
    def initialize(template, group)
      super(template, 'Gruppe erstellen', :plus)
      @group = group
      init_items
    end
    
    private
    
    def init_items
      group.possible_children.each do |type|
        link = template.new_group_path(group: { parent_id: group.id, type: type.sti_name})
        item(type.label, link)
      end
    end
    
  end
end