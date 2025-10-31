class ActiveViewLogger
  def start(name, id, payload)
    logger&.debug(colored("vvvvv Rendering main template " + "v" * 120))
  end

  def finish(name, id, payload)
    logger&.debug(colored("^^^^^ Rendered main template " + "^" * 121))
  end

  def colored(message)
    "\e[1;33m#{message}\e[0m"
  end

  def logger
    ActionView::Base.logger
  end
end

ActiveSupport::Notifications.subscribe("render_template.action_view", ActiveViewLogger.new)

