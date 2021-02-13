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
    expect {
      yield
    }.not_to change { Delayed::Job.where('handler like "%ActionMailer::MailDeliveryJob%"').count }
  end

  def expect_enqueued_mail_jobs(count:)
    expect {
      yield
    }.to change { Delayed::Job.where('handler like "%ActionMailer::MailDeliveryJob%"').count }.by(count)
  end
end
