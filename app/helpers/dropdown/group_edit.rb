# encoding: utf-8
module Dropdown
  class GroupEdit < Base
    
    attr_reader :group
    
    def initialize(template, group)
      super(template, 'Bearbeiten', :edit)
      @group = group
      @main_link = template.edit_group_path(group)
      init_items
    end
    
    private
    
    def init_items
      item('Fusionieren', template.merge_group_path(group))
      item('Verschieben', template.move_group_path(group))
      
      if !group.protected? && template.can?(:destroy, group)
        divider
        item('Löschen', 
             template.group_path(group), 
             :data => { :confirm => template.ti(:confirm_delete),
                        :method => :delete }) 
      end
    end
  end
end