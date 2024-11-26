# frozen_string_literal: true

#  Copyright (c) 2024-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

if Rails.env.development? || Rails.env.test?
  Niceql.configure do |c|
    # You can adjust pg_adapter in prooduction at your own risk!
    # If you need it in production use exec_niceql
    # default: false
    # c.pg_adapter_with_nicesql = Rails.env.development?

    # this are default settings, change it to your project needs
    # c.indentation_base = 2
    # c.open_bracket_is_newliner = false
    # c.prettify_active_record_log_output = false
  end
end
