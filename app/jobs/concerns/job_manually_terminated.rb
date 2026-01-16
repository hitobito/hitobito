class JobManuallyTerminated < StandardError
  def initialize(msg = "This job was manually terminated")
    super
  end
end
