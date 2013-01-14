# encoding: utf-8
module Subscriber
  class GroupController < BaseController
    
    skip_authorize_resource # must be in leaf class
    
    before_render_form :replace_validation_errors
    before_render_form :load_role_types
    
    # GET query queries available groups via ajax
    def query
      groups = []
      if params.has_key?(:q) && params[:q].size >= 3
        groups = @group.sister_groups_with_descendants.
                        where(search_condition('groups.name', 'parents_groups.name')).
                        includes(:parent).
                        order('groups.lft').
                        limit(10)
        groups = decorate(groups)
      end
      
      render json: groups.collect(&:as_typeahead)
    end
    
    # GET roles renders a list of roles for a given group via ajax
    def roles
      load_role_types
    end
   
    private
    
    def assign_attributes
      super
      entry.role_types = model_params[:role_types] if model_params
    end
    
    def load_role_types
      @role_types = Role::TypeList.new(subscriber.class) if subscriber
    end
    
    def subscriber
      @selected_group ||= @group.sister_groups_with_descendants.
                                 where(id: subscriber_id).
                                 first
    end
    
    def replace_validation_errors
      if entry.errors[:subscriber_type].present?
        entry.errors[:subscriber].clear
        entry.errors[:subscriber_id].clear
        entry.errors[:subscriber_type].clear
        entry.errors.add(:base, 'Gruppe muss ausgewählt werden')
      end
    end
  end
end