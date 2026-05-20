# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "ActiveStorage missing files", type: :request do
  let(:person) { people(:bottom_member) }

  before { sign_in(person) }

  it "returns 404 when file is missing" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("cool image"),
      filename: "imagesocoolthatitdoesntexist.jpg",
      content_type: "image/jpeg"
    )
    person.picture.attach(blob)
    blob.service.delete(blob.key)

    expect do
      get rails_representation_path(blob.representation(resize_to_fill: [32, 32]))
    end.not_to raise_error

    expect(response).to have_http_status(:not_found)
  end
end
