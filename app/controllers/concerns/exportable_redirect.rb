#  Copyright (c) 2018-2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ExportableRedirect
  extend ActiveSupport::Concern

  class PersonRequired < StandardError; end

  included do
    rescue_from PersonRequired do
      render plain: I18n.t("global.export_requires_person"), status: :not_acceptable
    end
  end

  private

  def exporting_person_id
    current_person&.id || raise(PersonRequired)
  end

  def redirect_after_enqueued_export(redirection_target = {returning: true})
    flash[:notice] = translate(
      :export_enqueued, default: :"global.export_enqueued",
      overview_link: helpers.link_to(t("job_observations.index.title"), job_observations_path)
    )

    redirect_to redirection_target
  end
end
