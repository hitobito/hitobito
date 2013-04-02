class MailRelayJob < RecurringJob

  run_every Settings.email.retriever.interval.minutes

  def perform_internal
    MailRelay::Lists.relay_current
  end

  def error(job, exception)
    if exception.is_a?(MailRelay::Error)
      super(job, exception.original, mail: exception.mail)
    else
      super(job, exception)
    end
  end
end