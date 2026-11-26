# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Chrome >= 158 rejects the wildcard origin Capybara 3.40 uses to clear storage on reset.
module CapybaraChromeResetFix
  private

  def execute_cdp(cmd, params = {})
    super
  rescue Selenium::WebDriver::Error::InvalidArgumentError
    raise unless cmd == "Storage.clearDataForOrigin" && params[:origin] == "*"

    super("Network.clearBrowserCookies")
    capybara_server_origins.each do |origin|
      super(cmd, params.merge(origin: origin))
    end
  end

  def capybara_server_origins
    [Capybara.app_host, Capybara.current_session.server&.base_url].compact.uniq
  rescue StandardError
    []
  end
end

Capybara::Selenium::Driver::ChromeDriver.prepend(CapybaraChromeResetFix)
