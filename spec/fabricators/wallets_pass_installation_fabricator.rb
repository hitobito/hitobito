# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

Fabricator(:wallets_pass_installation, class_name: "Wallets::PassInstallation") do
  pass
  wallet_type { :google }
  state { :active }
  needs_sync { false }
  locale { I18n.locale.to_s }
end
