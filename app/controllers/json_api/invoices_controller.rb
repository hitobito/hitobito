# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class JsonApi::InvoicesController < JsonApiController
  def index
    authorize!(:index, Invoice)
    super
  end

  def update
    authorize!(:update, entry)
    super
  end

  def show
    authorize!(:show, entry)
    super
  end

  private

  def entry
    @entry ||= Invoice.joins(:group).find(params[:id])
  end
end
