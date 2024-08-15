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
    expect do
      yield
    end.not_to change { enqueued_mail_jobs_count }
  end

  def expect_enqueued_mail_jobs(count:)
    expect do
      yield
    end.to change { enqueued_mail_jobs_count }.by(count)
  end

  def enqueued_mail_jobs_count
    Delayed::Job.where('handler like "%ActionMailer::MailDeliveryJob%"').count
  end
end
