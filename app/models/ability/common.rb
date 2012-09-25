module Ability::Common
  extend ActiveSupport::Concern
  
  include CanCan::Ability
  
  included do
    
    attr_reader :user,
                :user_groups, 
                :groups_group_full, 
                :groups_layer_full, 
                :groups_layer_read,
                :layers_read,
                :layers_full
   end
              

  def initialize(user)
    @user = user
    init_groups(user)
    
    alias_action :update, :destroy, :to => :modify
  end
  
  private
  
  def init_groups(user)
    @user_groups = user.groups.to_a
    @groups_group_full = user.groups_with_permission(:group_full).to_a
    @groups_layer_full = user.groups_with_permission(:layer_full).to_a
    @groups_layer_read = user.groups_with_permission(:layer_read).to_a

    @layers_read = layers(groups_layer_full, groups_layer_read).collect(&:id)
    @layers_full = layers(groups_layer_full).collect(&:id)
    @groups_group_full.collect!(&:id)
    @groups_layer_full.collect!(&:id)
    @groups_layer_read.collect!(&:id)
    @user_groups.collect!(&:id)
  end
  
  def layers(*groups)
    groups.flatten.collect(&:layer_group).uniq
  end
  
  def collect_ids(collection)
    collection.collect(&:id)
  end
  
  # Are any items of the existing list present in the list of required items? 
  def contains_any?(required, existing)
    (required & existing).present?
  end

  def modify_permissions?
    @groups_group_full.present? || @groups_layer_full.present?
  end
  
end
