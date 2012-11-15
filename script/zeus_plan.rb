require 'zeus/rails'
class MyPlan < Zeus::Rails
  def server_environment
    Bundler.require(:assets)
  end
  def development_environment
    Bundler.require(:development, :assets)
    ::Rails.env = ENV['RAILS_ENV'] = "development"
    require APP_PATH
    ::Rails.application.require_environment!
  end

end
Zeus.plan = MyPlan.new
