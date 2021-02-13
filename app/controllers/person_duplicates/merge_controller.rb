# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PersonDuplicates
  class MergeController < ApplicationController
    before_action :authorize_action

    def new
    end

    def create
      PersonDuplicate.transaction do
        entry.destroy!
        People::Merger.new(source, destination, current_user).merge!
      end

      redirect_to group_person_path(destination.primary_group, destination), notice: success_message
    end

    private

    def destination
      dst_person_2? ? entry.person_2 : entry.person_1
    end

    def source
      dst_person_2? ? entry.person_1 : entry.person_2
    end

    def dst_person_2?
      params[:person_duplicate][:dst_person].eql?("person_2")
    end

    def success_message
      I18n.t("person_duplicates.merge.success")
    end

    def entry
      @entry ||= PersonDuplicate.find(params[:id])
    end

    def authorize_action
      authorize!(:manage_person_duplicates, group) &&
        authorize!(:merge, entry)
    end

    def group
      @group ||= Group.find(params[:group_id])
    end
  end
end
