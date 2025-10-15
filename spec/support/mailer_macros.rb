#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MailerMacros
  def last_email
    ActionMailer::Base.deliveries.last
  end

  def reset_email
    ActionMailer::Base.deliveries = []
  end

  def expect_no_enqueued_mail_jobs
    ActiveJob::Base.queue_adapter = :delayed_job
    expect { yield }.not_to change { enqueued_mail_jobs_count }
  ensure
    ActiveJob::Base.queue_adapter = :test
  end

  def expect_enqueued_mail_jobs(count:)
    ActiveJob::Base.queue_adapter = :delayed_job
    expect { yield }.to change { enqueued_mail_jobs_count }.by(count)
  ensure
    ActiveJob::Base.queue_adapter = :test
  end

  def enqueued_mail_jobs_count
    Delayed::Job.where("handler ILIKE ?", "%ActionMailer::MailDeliveryJob%").count
  end
end
