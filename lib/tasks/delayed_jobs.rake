# frozen_string_literal: true

#  Copyright (c) 2022-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

namespace :delayed_job do
  desc 'Schedule Background-Jobs'
  task :schedule => [:environment, :'db:abort_if_pending_migrations'] do
    next if Rails.env.test?

    ActionMailer::Base.default from: Settings.email.sender

    if ActiveRecord::Base.connection.data_source_exists?('delayed_jobs')

      if MailConfig.legacy?
        MailRelayJob.new.schedule
      else
        MailingLists::MailRetrieverJob.new.schedule
      end

      SphinxIndexJob.new.schedule if Hitobito::Application.sphinx_present? && Hitobito::Application.sphinx_local?
      DownloadCleanerJob.new.schedule
      SessionsCleanerJob.new.schedule
      WorkerHeartbeatCheckJob.new.schedule
      ReoccuringMailchimpSynchronizationJob.new.schedule
      Address::CheckValidityJob.new.schedule if Settings.addresses.token
      Address::ImportJob.new.schedule if Settings.addresses.token
      People::DuplicateLocatorJob.new.schedule
      Payments::EbicsImportJob.new.schedule
    end
  end

  task :clear => [:environment] do
    Delayed::Job.delete_all
  end
end
