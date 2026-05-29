# frozen_string_literal: true

Fabricator(:personal_document) do
  person { Fabricate(:person) }
  author { Fabricate(:person) }
  personal_document_label
  file do
    Rack::Test::UploadedFile.new(
      File.open(Rails.root.join('spec', 'fixtures', 'files', 'images', 'logo.png'))
    )
  end
end
