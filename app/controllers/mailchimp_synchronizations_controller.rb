#  Copyright (c) 2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailchimpSynchronizationsController < ApplicationController
  def create
    mailing_list = MailingList.find(params[:mailing_list_id])

    authorize!(:update, mailing_list)

    MailchimpSynchronizationJob.new(mailing_list.id).enqueue!
    flash[:notice] = translate(
      ".wait_for_synchronization",
      overview_link: helpers.link_to(t("job_observations.index.title"), job_observations_path)
    )

    redirect_to(action: :index, controller: :subscriptions)
  end
end
