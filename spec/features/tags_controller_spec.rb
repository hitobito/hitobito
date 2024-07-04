# frozen_string_literal: true

require "spec_helper"

describe TagsController, js: true do
  subject { page }

  let(:top_leader) { people(:top_leader) }
  let!(:validation_tags) do
    PersonTags::Validation.tag_names.collect do |t|
      ActsAsTaggableOn::Tag.create!(name: t)
    end
  end

  let(:tag1) { Fabricate(:tag) }
  let(:tag2) { Fabricate(:tag) }
  let!(:tag3) { Fabricate(:tag) }

  let!(:tag1_owner) { fabricate_tagged_person([tag1]) }
  let!(:tag2_owner) { fabricate_tagged_person([tag2]) }
  let!(:all_tag_owner) { fabricate_tagged_person([tag1, tag2]) }

  before do
    sign_in
    visit tags_path
  end

  it "merges tags" do
    find(:css, "#ids_[value='#{tag1.id}']").set(true)
    find(:css, "#ids_[value='#{tag2.id}']").set(true)

    click_link("Zusammenführen")
    expect(page).to have_content "Sollen die gewählten Tags zusammengeführt werden?"
    fill_in id: "tags_merge_name", with: "Fantastic"
    click_button("Zusammenführen")

    is_expected.not_to have_content(tag2.name)
    is_expected.to have_content("Fantastic")
  end

  private

  def fabricate_tagged_person(tags)
    person = Fabricate(:person)
    person.update!(tags: tags)
    person
  end
end
