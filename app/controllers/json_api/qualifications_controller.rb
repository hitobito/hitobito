# frozen_string_literal: true

#  Copyright (c) 2012-2026, Bund der Pfadfinderinnen und Pfadfinder e.V.. This file is part of
#  hitobito and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class JsonApi::QualificationsController < JsonApiController
  def index
    authorize!(:index, Qualification)
    super
  end

  def create
    authorize!(:create, Qualification)
    super
  end

  def show
    authorize!(:show, entry)
    super
  end

  def destroy
    authorize!(:destroy, entry)
    super
  end

  private

  def entry
    @entry ||= Qualification.find(params[:id])
  end
end
