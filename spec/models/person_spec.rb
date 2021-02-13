# vim:fileencoding=utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: people
#
#  id                     :integer          not null, primary key
#  first_name             :string
#  last_name              :string
#  company_name           :string
#  nickname               :string
#  company                :boolean          default(FALSE), not null
#  email                  :string
#  address                :string(1024)
#  zip_code               :string
#  town                   :string
#  country                :string
#  gender                 :string(1)
#  birthday               :date
#  additional_information :text
#  contact_data_visible   :boolean          default(FALSE), not null
#  created_at             :datetime
#  updated_at             :datetime
#  encrypted_password     :string
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string
#  last_sign_in_ip        :string
#  picture                :string
#  last_label_format_id   :integer
#  creator_id             :integer
#  updater_id             :integer
#  primary_group_id       :integer
#  failed_attempts        :integer          default(0)
#  locked_at              :datetime
#  authentication_token   :string
#

require "spec_helper"

describe Person do
  let(:person) { role.person.reload }

  subject { person }

  it "is not valid without any names" do
    expect(Person.new).to have(1).errors_on(:base)
  end

  it "company only with nickname is not valid" do
    expect(Person.new(company: true, nickname: "foo")).to have(1).errors_on(:company_name)
  end

  it "company only with company name is valid" do
    expect(Person.new(company: true, company_name: "foo")).to be_valid
  end

  it "real only with nickname is valid" do
    expect(Person.new(company: false, nickname: "foo")).to be_valid
  end

  it "real only with company_name is not valid" do
    expect(Person.new(company: false, company_name: "foo")).to have(1).errors_on(:base)
  end

  it "can be saved with emoji", :mysql do
    person = Person.new(company: false, nickname: "foo", additional_information: " Vegetarier😝 ")
    expect(person.save).to be true
    expect(person.errors.messages[:base].size).to be_zero
  end

  it "with login role does not require email" do
    group = groups(:top_group)
    person = Person.new(last_name: "Foo")

    expect(person).to be_valid

    role = Group::TopGroup::Member.new
    role.group_id = group.id
    person.roles << role

    expect(person).to have(0).error_on(:email)
  end

  it "can create person with role" do
    group = groups(:top_group)
    person = Person.new(last_name: "Foo", email: "foo@example.com")
    role = group.class.role_types.first.new
    role.group_id = group.id
    person.roles << role

    expect(person.save).to be_truthy
  end

  it "#order_by_name orders people by company_name or last_name" do
    Person.destroy_all
    p1 = Fabricate(:person, company: true, company_name: "ZZ", last_name: "AA")
    p2 = Fabricate(:person, company: false, company_name: "ZZ", first_name: "ZZ", last_name: "BB")
    p3 = Fabricate(:person, company: true, company_name: "AA", last_name: "ZZ")
    p4 = Fabricate(:person, company: false, first_name: "AA", last_name: "BB")

    expect(Person.order_by_name.collect(&:to_s)).to eq([p3, p4, p2, p1].collect(&:to_s))
  end

  context "with one role" do
    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

    its(:layer_groups) { should == [groups(:top_layer)] }

    it "has layer_and_below_full permission in top_group" do
      expect(person.groups_with_permission(:layer_and_below_full)).to eq([groups(:top_group)])
    end

    it "found deleted last role" do
      deletion_date = DateTime.current
      expect(person.roles.count).to eq 1
      role.update(deleted_at: deletion_date)
      expect(person.roles.count).to eq 0
      expect(person.decorate.last_role.deleted_at.to_time.to_i).to eq(deletion_date.to_time.to_i)
    end
  end

  context "with multiple roles in same layer" do
    let(:role) do
      role1 = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
      Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one), person: role1.person)
    end

    its(:layer_groups) { should == [groups(:bottom_layer_one)] }

    it "has layer_and_below_full permission in top_group" do
      expect(person.groups_with_permission(:layer_and_below_full)).to eq([groups(:bottom_layer_one)])
    end

    it "has no layer_and_below_read permission" do
      expect(person.groups_with_permission(:layer_and_below_read)).to be_empty
    end

    it "only layer role is visible from above" do
      expect(person.groups_where_visible_from_above).to eq([groups(:bottom_layer_one)])
    end

    it "is not visible from above for bottom group" do
      g = groups(:bottom_group_one_one)
      expect(g.people.visible_from_above(g)).not_to include(person)
    end

    it "is visible from above for bottom layer" do
      g = groups(:bottom_layer_one)
      expect(g.people.visible_from_above(g)).to include(person)
    end

    it "preloads groups with the given scope" do
      p = Person.preload_groups.find(person.id)
      expect(p.groups).to be_loaded
      expect(p.groups.to_set).to eq([groups(:bottom_group_one_one), groups(:bottom_layer_one)].to_set)
    end

    it "preloads roles with the given scope" do
      p = Person.preload_groups.find(person.id)
      expect(p.roles).to be_loaded
      expect(p.roles.first.association(:group)).to be_loaded
    end

    it "in_layer returns person for this layer" do
      expect(Person.in_layer(groups(:bottom_group_one_one))).to match_array([people(:bottom_member), person])
    end

    it "in_or_below returns person for above layer" do
      expect(Person.in_or_below(groups(:top_layer))).to match_array([people(:bottom_member), people(:top_leader), person])
    end
  end

  context "with multiple roles in different layers" do
    let(:role) do
      role1 = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
      Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one), person: role1.person)
    end

    its(:layer_groups) { should have(2).items }
    its(:layer_groups) { should include(groups(:top_layer), groups(:bottom_layer_one)) }

    it "has contact_data permission in both groups" do
      expect(person.groups_with_permission(:contact_data)).to match_array([groups(:top_group), groups(:bottom_layer_one)])
    end

    it "both groups are visible from above" do
      expect(person.groups_where_visible_from_above).to match_array([groups(:top_group), groups(:bottom_layer_one)])
    end

    it "whole hierarchy may view this person" do
      expect(person.above_groups_where_visible_from).to match_array([groups(:top_layer), groups(:top_group), groups(:bottom_layer_one)])
    end

    it "in_layer returns person for this layer" do
      expect(Person.in_layer(groups(:bottom_group_one_one))).to match_array([people(:bottom_member), person])
    end

    it "in_or_below returns person for any layer" do
      expect(Person.in_or_below(groups(:top_layer))).to match_array([people(:bottom_member), people(:top_leader), person])
    end
  end

  context "with invisible role" do
    let(:group) { groups(:bottom_group_one_one) }
    let(:role) { Fabricate(Group::BottomGroup::Member.name.to_sym, group: group) }

    it "has not role that is visible from above" do
      expect(person.groups_where_visible_from_above).to be_empty
    end

    it "is not visible from above without arguments" do
      expect(group.people.visible_from_above).not_to include(person)
    end

    it "is not visible from above without arguments" do
      expect(group.people.visible_from_above(group)).not_to include(person)
    end

    it "is not visible from above in combination with other scopes" do
      expect(Person.in_or_below(groups(:top_layer)).visible_from_above).not_to include(person)
    end
  end

  context "devise recoverable" do
    let(:group) { groups(:bottom_group_one_one) }
    let(:person) { Fabricate(Group::BottomGroup::Member.name.to_sym, group: group).person.reload }

    it "can reset password" do
      expect { person.send_reset_password_instructions }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end
  end

  context "#ignored_country?" do
    it "ignores ch, empty" do
      person = Person.new(country: nil)
      expect(person.ignored_country?).to be_truthy
      person = Person.new(country: "CH")
      expect(person.ignored_country?).to be_truthy
    end

    it "does not ignore other countries" do
      person = Person.new(country: "USA")
      expect(person.ignored_country?).to be_falsey
    end
  end

  context "#destroy" do
    it "destroys all roles" do
      person = people(:top_leader)
      person.roles.first.update_attribute(:created_at, 2.years.ago)
      expect { person.destroy }.to change { Role.with_deleted.count }.by(-1)
    end
  end

  context "#save" do
    it "does not save person with duplicate email even when validation fails" do
      person = Person.new
      person.first_name = "Foo"
      person.email = people(:top_leader).email
      expect(person.save(validate: false)).to be_falsey
      expect(person.errors[:email]).to eq(["ist bereits vergeben. Diese Adresse muss für alle " \
                                        "Personen eindeutig sein, da sie beim Login verwendet " \
                                        "wird. Du kannst jedoch unter 'Weitere E-Mails' " \
                                        "Adressen eintragen, welche bei anderen Personen als " \
                                        "Haupt-E-Mail vergeben sind (Die Haupt-E-Mail kann leer " \
                                        "gelassen werden).\n"])
    end
  end

  context "#generate_reset_password_token!" do
    it "generates the same token as #send_reset_password_instructions" do
      person = people(:top_leader)

      token = person.generate_reset_password_token!
      enc = person.reload.reset_password_token
      expect(enc).to be_present
      person.clear_reset_password_token!
      expect(person.reload.reset_password_token).to be_nil

      # as we cannot seed the token generator, we just compare the sizes..
      expect(person.send_reset_password_instructions.size).to eq(token.size)
      expect(person.reset_password_token.size).to eq(enc.size)
    end
  end

  context "paper trail", versioning: true do
    context "stores person id in main id" do
      it "on create" do
        p = nil
        expect do
          p = Person.new(first_name: "Foo")
          p.save!
        end.to change { PaperTrail::Version.count }.by(1)

        v = PaperTrail::Version.order(:created_at).last
        expect(v.event).to eq("create")
        expect(v.main_id).to eq(p.id)
      end
    end
  end

  context "#years" do
    before { allow(Time.zone).to receive_messages(now: Time.zone.parse("2014-03-01 11:19:50")) }

    it "is nil if person has no birthday" do
      expect(Person.new.years).to be_nil
    end

    [["2006-02-12", 8],
      ["2005-03-15", 8],
      ["2004-02-29", 10]].each do |birthday, years|
       it "is #{years} years old if born on #{birthday}" do
         expect(Person.new(birthday: birthday).years).to eq years
       end
     end
  end

  context "#country_label" do
    it "translates two letter code using locale" do
      person = Person.new(country: "IT")
      expect(person.country_label).to eq "Italien"
    end

    it "returns country value if value is not a two letter country code" do
      person = Person.new(country: "Svizzera")
      expect(person.country_label).to eq "Svizzera"
    end
  end

  context "zip code" do
    let(:person) { Person.new(last_name: "Foo") }

    context "switzerland" do
      def should_be_valid_swiss_post_code
        [nil, "Schweiz"].each do |c|
          person.country = c
          expect(person).to be_valid
        end
      end

      def should_not_be_valid_swiss_post_code
        [nil, "CH"].each do |c|
          person.country = c
          expect(person).not_to be_valid
        end
      end

      it "should allow numerical post codes" do
        should_be_valid_swiss_post_code

        person.zip_code = "1000"
        should_be_valid_swiss_post_code

        person.zip_code = "1234"
        should_be_valid_swiss_post_code

        person.zip_code = "3007"
        should_be_valid_swiss_post_code

        person.zip_code = "9000"
        should_be_valid_swiss_post_code
      end

      it "should not allow alphanumerical post codes" do
        person.zip_code = "10115"
        should_not_be_valid_swiss_post_code

        person.zip_code = "01200"
        should_not_be_valid_swiss_post_code

        person.zip_code = "3000 "
        should_not_be_valid_swiss_post_code

        person.zip_code = "99577-0727"
        should_not_be_valid_swiss_post_code

        person.zip_code = "2597 GV 75"
        should_not_be_valid_swiss_post_code

        person.zip_code = "C1420"
        should_not_be_valid_swiss_post_code

        person.zip_code = "SW1W 0NY"
        should_not_be_valid_swiss_post_code
      end
    end

    context "foreign country" do
      it "can be empty" do
        person.country = "ES"
        expect(person).to be_valid
      end

      it "should allow 5-digit numbers" do
        person.country = "DE"
        person.zip_code = "10115"
        expect(person).to be_valid
      end

      it "should allow leading zeros" do
        person.country = "FR"
        person.zip_code = "01210"
        expect(person).to be_valid

        person.country = "FR"
        person.zip_code = "00120"
        expect(person).to be_valid
      end

      it "should allow non-numeric characters" do
        person.country = "US"
        person.zip_code = "99577-0727"
        expect(person).to be_valid

        person.country = "NL"
        person.zip_code = "2597 GV 75"
        expect(person).to be_valid

        person.country = "AR"
        person.zip_code = "C1420"
        expect(person).to be_valid

        person.country = "PL"
        person.zip_code = "SW1W 0NY"
        expect(person).to be_valid

        person.country = "CA"
        person.first_name = "SANTA"
        person.last_name = "CLAUS"
        person.address = "NORTH POLE"
        person.zip_code = "H0H 0H0"
        expect(person).to be_valid
      end
    end
  end

  context "#location" do
    it "finds location for zip_code" do
      expect(Person.new.location).to be_nil
      expect(Person.new(zip_code: 3000).location).to be_nil
      Location.create!(zip_code: 3000, name: "Bern", canton: "be")
      expect(Person.new(zip_code: 3000).location).to be_present
    end

    it "reads canton from location if present" do
      expect(Person.new.canton).to be_nil
      Location.create!(zip_code: 3000, name: "Bern", canton: "be")
      expect(Person.new(zip_code: 3000).canton).to eq "be"
    end

    it "may preload location for various zip_codes" do
      l = Location.create!(zip_code: 1200, name: "Lausanne", canton: "be")
      Fabricate(:person, zip_code: "01200", country: "DE")
      Fabricate(:person, zip_code: "1200")
      Fabricate(:person, zip_code: "1200 ", country: "DE")
      list = Person.includes(:location).where("zip_code LIKE '%1200%'").order(:zip_code).to_a
      expect(list.first.location).to be_nil
      expect(list.second.location).to eq(l)
      expect(list.third.location).to be_nil
    end
  end

  it "#finance_groups returns list of group on which user may manage invoices" do
    expect(people(:bottom_member).finance_groups).to eq [groups(:bottom_layer_one)]
  end

  it "#filter_attrs returns list of filterable attributes" do
    attrs = Person.filter_attrs
    expect(attrs[:first_name]).to eq(label: "Vorname", type: :string)
    expect(attrs[:last_name]).to eq(label: "Nachname", type: :string)
    expect(attrs[:nickname]).to eq(label: "Übername", type: :string)
    expect(attrs[:company_name]).to eq(label: "Firmenname", type: :string)
    expect(attrs[:email]).to eq(label: "Haupt-E-Mail", type: :string)
    expect(attrs[:address]).to eq(label: "Adresse", type: :text)
    expect(attrs[:zip_code]).to eq(label: "PLZ", type: :string)
    expect(attrs[:town]).to eq(label: "Ort", type: :string)
    expect(attrs[:country]).to eq(label: "Land", type: :string)

    expect(Person.filter_attrs.count).to eq(Person::FILTER_ATTRS.count)
  end

  it "#filter_attrs is controlled by attributes define in Person::FILTER_ATTRS" do
    stub_const("Person::FILTER_ATTRS", [:first_name, [:active_years, :custom_type]])
    attrs = Person.filter_attrs
    expect(attrs[:first_name]).to eq(label: "Vorname", type: :string)
    expect(attrs[:active_years]).to eq(label: "Active years", type: :custom_type)
  end

  describe "#picture" do
    include CarrierWave::Test::Matchers
    let(:person) { Fabricate(:person) }

    before do
      person.picture.store!(File.open("spec/fixtures/person/test_picture.jpg"))
    end

    describe "default" do
      it "scales down an image to be exactly 32 by 32 pixels" do
        expect(person.picture.thumb).to be_no_larger_than(32, 32)
      end
    end

    describe "#thumb" do
      it "scales down an image to be no wider than 512 pixels" do
        expect(person.picture).to have_dimensions(512, 512)
      end
    end
  end

  describe "e-mail validation" do
    let(:person) { people(:top_leader) }

    before { allow(Truemail).to receive(:valid?).and_call_original }

    it "does not allow invalid e-mail address" do
      person.email = "blabliblu-ke-email"

      expect(person).not_to be_valid
      expect(person.errors.messages[:email].first).to eq("ist nicht gültig")
    end

    it "allows blank e-mail address" do
      person.email = "   "

      expect(person).to be_valid
      expect(person.email).to be_nil
    end

    it "can create two people with empty email" do
      expect { 2.times { Fabricate(:person, email: "") } }.to change { Person.count }.by(2)
    end

    it "cannot create two people with same email" do
      expect { 2.times { Fabricate(:person, email: "foo@bar.com") } }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "does not allow e-mail address with non-existing domain" do
      person.email = "dude@gitsäuäniä.it"

      expect(person).not_to be_valid
      expect(person.errors.messages[:email].first).to eq("ist nicht gültig")
    end

    it "does not allow e-mail address with domain without mx record" do
      person.email = "dude@bluewin.com"

      expect(person).not_to be_valid
      expect(person.errors.messages[:email].first).to eq("ist nicht gültig")
    end

    it "does allow valid e-mail address" do
      person.email = "dude@puzzle.ch"

      expect(person).to be_valid
    end
  end

  describe "invalid e-mail tags" do
    let(:person) { people(:top_leader) }
    let(:taggings) do
      ActsAsTaggableOn::Tagging
        .where(taggable: person)
    end

    before { allow(Truemail).to receive(:valid?).and_call_original }

    before do
      person.email = "not-an-email"
      person.save!(validate: false)
    end

    before do
      AdditionalEmail
        .new(contactable: person,
             email: "no-email@no-domain")
        .save!(validate: false)
    end

    before { Contactable::EmailValidator.new.validate_people }

    it "removes invalid e-mail tags when saving" do
      expect(taggings.count).to eq(2)

      person.email = "info@hitobito.ch"
      person.additional_emails.first.email = "hitobito@puzzle.ch"
      person.save!

      expect(taggings.reload.count).to eq(0)
    end
  end

  describe "invalid address tags" do
    let (:person) { people(:bottom_member) }
    let(:taggings) do
      ActsAsTaggableOn::Tagging
        .where(taggable: person)
    end

    before { Contactable::AddressValidator.new.validate_people }

    it "removes invalid address tags when saving new address" do
      expect(taggings.count).to eq(1)

      person.address = "Belpstrasse 37"
      person.save!

      expect(taggings.reload.count).to eq(0)
    end

    it "removes invalid address tags when saving new town" do
      expect(taggings.count).to eq(1)

      person.town = "Bern"
      person.save!

      expect(taggings.reload.count).to eq(0)
    end

    it "removes invalid address tags when saving new zip_code" do
      expect(taggings.count).to eq(1)

      person.zip_code = 3007
      person.save!

      expect(taggings.reload.count).to eq(0)
    end
  end

  describe "person_duplicates" do
    let!(:duplicate1) { Fabricate(:person_duplicate) }
    let!(:duplicate2) do
      PersonDuplicate.create!(person_1: person_1, person_2: people(:top_leader))
    end
    let(:person_1) { duplicate1.person_1 }

    it "deletes person duplicates if person is deleted" do
      expect do
        person_1.destroy!
      end.to change(PersonDuplicate, :count).by(-2)
    end
  end
end
