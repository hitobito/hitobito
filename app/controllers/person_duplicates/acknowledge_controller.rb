# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PersonDuplicates
  class AcknowledgeController < ApplicationController

    before_action :authorize_action

    def new; end

    def create
      entry.update!(acknowledged: true)

      redirect_to group_person_duplicates_path(group), notice: success_message
    end

    private
    
    def success_message
      I18n.t('person_duplicates.acknowledge.success')
    end

    def entry
      @entry ||= PersonDuplicate.find(params[:id])
    end

    def group
      @group ||= Group.find(params[:group_id])
    end

    def authorize_action
      authorize!(:manage_person_duplicates, group) && authorize!(:acknowledge, entry)
    end

  end
end
