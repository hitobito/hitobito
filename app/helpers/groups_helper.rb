# encoding: utf-8
module GroupsHelper
  
  def group_edit_button
    dropdown_button('Bearbeiten',
                    group_edit_dropdown_links,
                    :edit,
                    edit_group_path(entry))
  end
  
  private
  
  def group_edit_dropdown_links
    links = []
    links << link_to('Fusionieren', merge_group_path(entry))
    links << link_to('Verschieben', move_group_path(entry))
    if !entry.protected? && can?(:destroy, entry)
      links << nil
      links << link_action_destroy(entry, 'Löschen') 
    end
    links
  end
end
