#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ExportableRedirect
  private

  def redirect_after_enqueued_export(redirection_target = {returning: true})
    flash[:notice] = translate(
      :export_enqueued, default: :"global.export_enqueued",
      overview_link: helpers.link_to(t("job_observations.index.title"), job_observations_path)
    )

    redirect_to redirection_target
  end
end
