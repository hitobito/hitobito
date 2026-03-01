#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Rails.application.config.to_prepare do
  Passes::TemplateRegistry.reset!
  Passes::TemplateRegistry.register("default",
    pdf_class: "Export::Pdf::Passes::Default",
    pass_view_partial: "default",
    wallet_data_provider: Passes::WalletDataProvider)
end
