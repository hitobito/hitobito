# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module FeatureHelpers

  def sign_in(user = nil, confirm: true)
    user ||= people(:top_leader)
    user.confirm if confirm
    login_as(user, scope: :person)
  end

  def fill_in_trix_editor(id, with:)
    find(:xpath, "//trix-editor[@id='#{id}']").click.set(with)
  end

  private

  # retries block when expectation is not met
  def with_retries(attempt = 0, max_attempts: 3)
    yield
  rescue RSpec::Expectations::ExpectationNotMetError => e
    attempt += 1
    retry if attempt < max_attempts
    fail e
  end

  # catch some errors occuring now and then in capybara tests
  def obsolete_node_safe
    yield
  rescue Errno::ECONNREFUSED,
         Timeout::Error,
         Capybara::FrozenInTime,
         Capybara::ElementNotFound => e
    skip e.message
  end

  # due to concurrent requests in js specs, it happens that
  # stdout is not reset after silencing and thus completely disappears.
  # This method asserts the stdout is reset again after every test.
  def keeping_stdout
    old_stream = STDOUT.dup
    yield
  ensure
    STDOUT.reopen(old_stream)
  end

end
