class Ability::Base
  include CanCan::Ability
  
  attr_reader :groups_group_full, 
              :groups_layer_full, 
              :groups_layer_read,
              :layers_read,
              :layers_full
              

  def initialize(user)
    init_groups(user)
    
    alias_action :create, :update, :destroy, :to => :modify
  end
  
  private
  
  
  def init_groups(user)
    @groups_group_full = user.groups_with_permission(:group_full)
    @groups_layer_full = user.groups_with_permission(:layer_full)
    @groups_layer_read = user.groups_with_permission(:layer_read)
    @layers_read = layers(groups_layer_full, groups_layer_read)
    @layers_full = layers(groups_layer_full)
  end
  
  def show_person_permissions?
    @groups_group_full.present? || @groups_layer_full.present? || @groups_layer_read.present?
  end
  
  def modify_person_permissions?
    @groups_group_full.present? || @groups_layer_full.present?
  end
  
  def layers(*groups)
    groups.flatten.collect(&:layer_group).uniq
  end
  
  # Are any items of the existing list present in the list of required items? 
  def contains_any?(required, existing)
    (required & existing).present?
  end
  
end