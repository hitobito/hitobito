# frozen_string_literal: true

#  Copyright (c) 2023-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# rubocop:disable Rails/Output

class JobManager
  class_attribute :wagon_jobs, default: []

  def schedule
    jobs.each do |job_class|
      job_class.new.schedule
    end
  end

  def clear
    Delayed::Job.delete_all
  end

  def check
    scheduled, missing = jobs.partition do |job_class|
      job_class.new.scheduled?
    end

    puts "Scheduled: #{scheduled.to_sentence}" if scheduled.any?
    puts "Missing: #{missing.to_sentence}" if missing.any?
    puts 'All expected jobs are scheduled.' if missing.empty?

    missing.empty?
  end

  private

  def jobs
    [
      mail_jobs,
      sphinx_jobs,
      addresses_jobs,
      standard_jobs,
      wagon_jobs
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

  def standard_jobs # rubocop:disable Metrics/MethodLength
    [
      DownloadCleanerJob,
      Event::ParticipationCleanupJob,
      Payments::EbicsImportJob,
      People::DuplicateLocatorJob,
      People::CleanupJob,
      People::CreateRolesJob,
      People::DestroyRolesJob,
      ReoccuringMailchimpSynchronizationJob,
      SessionsCleanerJob,
      WorkerHeartbeatCheckJob
    ]
  end
end

# rubocop:enable Rails/Output
