#  Copyright (c) 2026 Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PaperTrail::VersionChangesetPresenter, :draper_with_helpers, versioning: true do
  let(:person) { people(:top_leader) }
  let(:version) { PaperTrail::Version.where(main_id: person.id).order(:created_at, :id).last }
  let(:view_context) { ActionController::Base.new.view_context }
  let(:presenter) { PaperTrail::VersionChangesetPresenter.new(version, view_context) }

  before do
    PaperTrail.request.whodunnit = nil
    view_context.extend(FormatHelper)
    person.update!(town: "Bern", zip_code: "3007")
  end

  subject { presenter.render }

  it "contains from and to attributes" do
    string = presenter.attribute_change(:first_name, "Hans", "Fritz")
    expect(string).to be_html_safe
    expect(string).to eq("Vorname wurde von <i>Hans</i> auf <i>Fritz</i> geändert.")
  end

  it "contains only from attribute" do
    string = presenter.attribute_change(:first_name, "Hans", " ")
    expect(string).to be_html_safe
    expect(string).to eq("Vorname <i>Hans</i> wurde gelöscht.")
  end

  it "contains only to attribute" do
    string = presenter.attribute_change(:first_name, nil, "Fritz")
    expect(string).to be_html_safe
    expect(string).to eq("Vorname wurde auf <i>Fritz</i> gesetzt.")
  end

  it "is empty without from and to " do
    string = presenter.attribute_change(:first_name, nil, "")
    expect(string).to be_blank
  end

  it "escapes html" do
    string = presenter.attribute_change(:first_name, nil, "<b>Fritz</b>")
    expect(string).to eq("Vorname wurde auf <i>&lt;b&gt;Fritz&lt;/b&gt;</i> gesetzt.")
  end

  it "formats according to column info" do
    now = Time.zone.local(2014, 6, 21, 18)
    string = presenter.attribute_change(:updated_at, nil, now)
    expect(string).to eq "Geändert wurde auf <i>21.06.2014 18:00</i> gesetzt."
  end

  it "translates i18n_enum values" do
    string = presenter.attribute_change(:language, "de", "fr")
    expect(string).to eq("Sprache wurde von <i>Deutsch</i> auf <i>Französisch</i> geändert.")
  end

  # We currently have to add a custom i18n key for this spec case because there is no sti model
  # with translated attributes that is paper trailed. We have this case in the sac_cas wagon but
  # the fix of the decorator is in core
  #
  # If the core ever gets a translated attribute specifically on a sti submodel (translation key is subtype)
  # this spec can be simplified by just using the existing translation.
  it "translates attribute label of translated attributes in sti models" do
    I18n.backend.store_translations(:de, {
      activerecord: {
        attributes: {
          "event/course": {
            translated_course_attribute: "I am translated"
          }
        }
      }
    })

    version.update!(item: events(:top_course).translations.first, item_subtype: "Event::Translation")
    string = presenter.attribute_change(:translated_course_attribute, "old value", "new value")

    expect(string).to eq("I am translated (de) Von Top Course wurde von " \
      "<i>old value</i> auf <i>new value</i> geändert.")
  end
end
