# This controller circumvents authorization so OpenShift/Kubernetes can
# inspect the application health without credentials.
# If we'd return 401 the application would be treated as unhealthy.
class HealthzController < ActionController::Base

  def show
    render json: AppStatusSerializer.new(app_status), status: app_status.code
  end

  private

  def app_status
    @app_status ||= AppStatus.new
  end
end
