class MailRelayJob < RecurringJob
  
  run_every Settings.email.retriever.interval.minutes
  
  def perform_internal
    MailRelay::Lists.relay_current
  end
  
end