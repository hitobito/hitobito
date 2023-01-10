# frozen_string_literal: true

#  Copyright (c) 2022-2023, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

namespace :delayed_job do
  desc 'Schedule Background-Jobs'
  task schedule: [:environment, :'db:abort_if_pending_migrations'] do
    next if Rails.env.test?

    HitobitoDelayedJobs.list.each do |job_class|
      job_class.new.schedule
    end
  end

  task clear: [:environment] do
    Delayed::Job.delete_all
  end
end

module HitobitoDelayedJobs
  module_function

  def list
    [
      mail_jobs,
      sphinx_jobs,
      addresses_jobs,
      standard_jobs
    ].flatten.compact
  end

  def mail_jobs
    if MailConfig.legacy?
      MailRelayJob
    else
      MailingLists::MailRetrieverJob
    end
  end

  def sphinx_jobs
    if Hitobito::Application.sphinx_present? && Hitobito::Application.sphinx_local?
      SphinxIndexJob
    end
  end

  def addresses_jobs
    if Settings.addresses.token
      [
        Address::CheckValidityJob,
        Address::ImportJob
      ]
    end
  end

  def standard_jobs
    [
      DownloadCleanerJob,
      Payments::EbicsImportJob,
      People::DuplicateLocatorJob,
      ReoccuringMailchimpSynchronizationJob,
      SessionsCleanerJob,
      WorkerHeartbeatCheckJob
    ]
  end

end
