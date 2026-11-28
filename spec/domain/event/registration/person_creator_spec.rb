# frozen_string_literal: true

#  Copyright (c) 2026, Berner Fachhochschule. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::Registration::PersonCreator do
  let(:event) { events(:top_event) }
  let(:group) { event.groups.first }
  let(:person) { Person.new }
  let(:attrs) { {first_name: "Barney", last_name: "Foo", email: "barney@example.com"} }
  let(:privacy_policy_accepted) { false }

  subject(:creator) do
    described_class.new(event: event, group: group, privacy_policy_accepted:,
      contact_data: Event::ParticipationContactData.new(event, person, attrs))
  end

  before { event.update!(required_contact_attrs: []) }

  it "creates the person" do
    expect { creator.save }.to change { Person.count }.by(1)
    expect(person).to be_persisted
  end

  it "does not create an invalid person" do
    attrs[:email] = ""

    expect(creator.save).to be false
    expect(person).to be_new_record
  end

  context "with privacy policy" do
    before do
      file = Rails.root.join("spec", "fixtures", "files", "images", "logo.png")
      image = ActiveStorage::Blob.create_and_upload!(io: File.open(file, "rb"),
        filename: "logo.png", content_type: "image/png").signed_id
      group.layer_group.update!(privacy_policy: image)
    end

    it "does not create the person without acceptance" do
      expect(creator.save).to be false
      expect(person).to be_new_record
    end

    context "accepted" do
      let(:privacy_policy_accepted) { true }

      it "stores the acceptance" do
        expect(creator.save).to be true
        expect(person.reload.privacy_policy_accepted_at).to be_present
      end
    end
  end

  context "with after_create callback" do
    let(:created) { [] }

    around do |example|
      log = created
      callback = ->(creator) { log << creator.person }
      described_class.after_create(callback)
      example.run
    ensure
      described_class.skip_callback(:create, :after, callback)
    end

    it "runs it for the created person" do
      creator.save

      expect(created).to eq [person]
    end

    it "does not run it when the person is invalid" do
      attrs[:email] = ""
      creator.save

      expect(created).to be_empty
    end
  end

  context "with failing after_create callback" do
    around do |example|
      callback = ->(_creator) { raise "role missing" }
      described_class.after_create(callback)
      example.run
    ensure
      described_class.skip_callback(:create, :after, callback)
    end

    it "creates no person" do
      expect do
        expect { creator.save }.to raise_error("role missing")
      end.not_to change { Person.count }
    end
  end
end
