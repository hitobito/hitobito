# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailRelayJob < RecurringJob

  run_every Settings.email.retriever.interval.minutes

  def perform_internal
    # only run if a retriever address is defined
    if Settings.email.retriever.config.address
      MailRelay::Lists.relay_current
    end
  end

  def error(job, exception)
    if exception.is_a?(MailRelay::Error)
      super(job, exception.original, mail: exception.mail)
    else
      super(job, exception)
    end
  end
end