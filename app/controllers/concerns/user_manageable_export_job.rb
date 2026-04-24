#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module UserManageableExportJob
  def respond_to_export_job(redirection_target: {returning: true}, render_command: nil)
    flash[:notice] = translate(:export_enqueued, default: :"groups.export_enqueued")

    if render_command
      render_command.call
    else
      redirect_to redirection_target
    end
  end
end
