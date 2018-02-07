require 'oat/adapters/json_api'

class AppStatusSerializer

  delegate :code, :store_ok?, to: :app_status

  attr_reader :app_status

  def initialize(app_status)
    @app_status = app_status
  end

  def to_json(a)
    {app_status: { code: code, store_ok?: store_ok? } }.to_json
  end

end
