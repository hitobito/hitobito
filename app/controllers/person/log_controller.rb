# frozen_string_literal: true

#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::LogController < ApplicationController

  before_action :authorize_action

  decorates :group, :person, :versions

  def index
    @versions = PaperTrail::Version.where(main_id: entry.id, main_type: Person.sti_name)
                                   .reorder('created_at DESC, id DESC')
                                   .includes(:item)
                                   .page(params[:page])
  end

  private

  def entry
    @entry ||= group.people.find(params[:id])
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def authorize_action
    authorize!(:log, entry)
  end

end
