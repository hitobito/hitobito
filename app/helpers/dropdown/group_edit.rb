# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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