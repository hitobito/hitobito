# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Subscriber
  class GroupController < BaseController

    skip_authorize_resource # must be in leaf class

    before_render_form :replace_validation_errors
    before_render_form :load_role_types
    before_render_form :load_possible_tags

    # GET query queries available groups via ajax
    def query
      groups = []
      if params.key?(:q) && params[:q].size >= 3
        groups = decorate(groups_query)
      end

      render json: groups.collect(&:as_typeahead)
    end

    # GET roles renders a list of roles for a given group via ajax
    def roles
      load_role_types
    end

    def edit
      @selected_group ||= Group.find(entry.subscriber_id)
      load_role_types
    end

    def update
      super do |format|
        format.html do
          redirect_to(group_mailing_list_subscriptions_path(mailing_list.group, mailing_list))
        end
      end
    end

    private

    def groups_query
      possible = Subscription.new(mailing_list: @mailing_list).possible_groups
      possible.where(search_condition('groups.name', 'parents_groups.name')).
               includes(:parent).
               references(:parent).
               order('groups.lft').
               limit(10)
    end

    def assign_attributes
      super
      if model_params
        entry.role_types = model_params[:role_types]
        entry.tag_list = model_params[:tag_list]
      end
    end

    def load_role_types
      @role_types = Role::TypeList.new(subscriber.class) if subscriber
    end

    def load_possible_tags
      @possible_tags ||= PersonTags::Translator.new.possible_tags
    end

    def subscriber
      @selected_group ||= Group.where(id: subscriber_id).first
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
