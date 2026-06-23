# frozen_string_literal: true

# Copyright (c) 2026. BienenSchweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

Fabricator(:personal_document) do
  person { Fabricate(:person) }
  author { Fabricate(:person) }
  personal_document_label
  file do
    Rack::Test::UploadedFile.new(
      Rails.root.join("spec", "fixtures", "files", "images", "logo.png")
    )
  end
end
