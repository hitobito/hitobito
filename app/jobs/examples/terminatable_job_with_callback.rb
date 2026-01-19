class Examples::TerminatableJobWithCallback < BaseJob
  prepend ManuallyTerminatable

  def perform
    loop do
      sleep 3
      Rails.logger.debug "Doing work..."
    end
  rescue JobManuallyTerminated
    Person.first.update!(first_name: "changed after job termination")
  end
end
