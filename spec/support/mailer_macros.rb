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
    expect { yield }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
  end

  def expect_enqueued_mail_jobs(count:)
    expect { yield }.to have_enqueued_job(ActionMailer::MailDeliveryJob).exactly(count).times
  end

  def enqueued_mail_jobs_count
    Delayed::Job.where("handler ILIKE ?", "%ActionMailer::MailDeliveryJob%").count
  end
end
