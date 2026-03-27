# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PersonDuplicates
  class MergeController < ApplicationController
    before_action :authorize_action

    helper_method :entry

    def new
    end

    def create
      return rerender_form(:unprocessable_content) unless entry.valid?(:merge)

      PersonDuplicate.transaction do
        entry.destroy!
        merger.merge!
      end

      redirect_to(
        group_person_path(destination.primary_group, destination),
        notice: success_message,
        alert: merger.validation_errors.map(&:to_s)
      )
    end

    private

    def merger = @merger ||= People::Merger.new(source, destination, current_user)

    def rerender_form(status)
      render turbo_stream: turbo_stream.replace(
        "edit_person_duplicate_#{entry.id}",
        partial: "person_duplicates/merge/form",
        locals: {entry: entry}
      ), status: status
    end

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
      key = merger.validation_errors.any? ? "success_with_validation_errors" : "success"
      I18n.t("person_duplicates.merge.#{key}")
    end

    def entry
      @entry ||= PersonDuplicate.find(params[:id])
    end

    def authorize_action
      if [entry.person_1, entry.person_2].all? { |p| cannot?(:update, p) }
        raise CanCan::AccessDenied.new
      end
      authorize!(:manage_person_duplicates, group)
    end

    def group
      @group ||= Group.find(params[:group_id])
    end
  end
end
