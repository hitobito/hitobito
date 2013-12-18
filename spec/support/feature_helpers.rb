# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module FeatureHelpers

  def sign_in(user = nil)
    user ||= people(:top_leader)
    visit person_session_path
    fill_in 'E-Mail', with: user.email
    fill_in 'Passwort', with: 'foobar'
    click_button 'Anmelden'
  end

  private

  # catch some errors occuring now and then in capybara tests
  def obsolete_node_safe
    begin
      yield
    rescue Errno::ECONNREFUSED,
           Timeout::Error,
           Capybara::FrozenInTime,
           Capybara::ElementNotFound,
           Capybara::Poltergeist::ObsoleteNode,
           Capybara::Poltergeist::TimeoutError => e
      pending e.message
    end
  end

end
