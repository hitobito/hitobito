# encoding: utf-8
module Dropdown
  class RoleAdd < Base
    
    attr_reader :group
    
    def initialize(template, group)
      super(template, 'Person hinzufügen', :plus)
      @group = group
      init_items
    end
    
    private

    def init_items
      group.possible_roles.each do |entry|
        item("als #{entry[:human]}", link(entry))
      end
    end

    def link(entry)
      template.new_group_role_path(group, role: { type: entry[:sti_name]})
    end

    
  end
end
