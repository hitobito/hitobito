class Examples::TerminatableJob < BaseJob
  prepend ManuallyTerminatable

  def perform
    loop do
      sleep 3
      Rails.logger.debug "Doing work..."
    end
  end
end
