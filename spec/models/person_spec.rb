# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: people
#
#  id                                   :integer          not null, primary key
#  additional_information               :text
#  address_care_of                      :string
#  authentication_token                 :string
#  birthday                             :date
#  blocked_at                           :datetime
#  company                              :boolean          default(FALSE), not null
#  company_name                         :string
#  confirmation_sent_at                 :datetime
#  confirmation_token                   :string
#  confirmed_at                         :datetime
#  contact_data_visible                 :boolean          default(FALSE), not null
#  country                              :string
#  current_sign_in_at                   :datetime
#  current_sign_in_ip                   :string
#  email                                :string
#  encrypted_password                   :string
#  encrypted_two_fa_secret              :text
#  event_feed_token                     :string
#  failed_attempts                      :integer          default(0)
#  family_key                           :string
#  first_name                           :string
#  gender                               :string(1)
#  household_key                        :string
#  housenumber                          :string(20)
#  inactivity_block_warning_sent_at     :datetime
#  language                             :string           default("de"), not null
#  last_name                            :string
#  last_sign_in_at                      :datetime
#  last_sign_in_ip                      :string
#  locked_at                            :datetime
#  membership_verify_token              :string
#  minimized_at                         :datetime
#  nickname                             :string
#  postbox                              :string
#  privacy_policy_accepted_at           :datetime
#  remember_created_at                  :datetime
#  reset_password_sent_at               :datetime
#  reset_password_sent_to               :string
#  reset_password_token                 :string
#  self_registration_reason_custom_text :string(100)
#  show_global_label_formats            :boolean          default(TRUE), not null
#  sign_in_count                        :integer          default(0)
#  street                               :string
#  town                                 :string
#  two_factor_authentication            :integer
#  unconfirmed_email                    :string
#  unlock_token                         :string
#  zip_code                             :string
#  created_at                           :datetime
#  updated_at                           :datetime
#  creator_id                           :integer
#  last_label_format_id                 :integer
#  primary_group_id                     :integer
#  self_registration_reason_id          :bigint
#  updater_id                           :integer
#
# Indexes
#
#  index_people_on_authentication_token         (authentication_token)
#  index_people_on_confirmation_token           (confirmation_token) UNIQUE
#  index_people_on_email                        (email) UNIQUE
#  index_people_on_event_feed_token             (event_feed_token) UNIQUE
#  index_people_on_first_name                   (first_name)
#  index_people_on_household_key                (household_key)
#  index_people_on_last_name                    (last_name)
#  index_people_on_reset_password_token         (reset_password_token) UNIQUE
#  index_people_on_self_registration_reason_id  (self_registration_reason_id)
#  index_people_on_unlock_token                 (unlock_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (self_registration_reason_id => self_registration_reasons.id)
#

require "spec_helper"

describe Person do
  let(:person) { role.person.reload }

  subject { person }

  context "scopes" do
    describe "preload_roles_unscoped" do
      it "preloads roles on #find" do
        person = Person.preload_roles_unscoped.find(people(:top_leader).id)
        expect(person.roles).to be_loaded
        expect(person.roles).to have(1).item
      end

      it "preloads roles unscoped" do
        people(:top_leader).roles.update_all(end_on: Date.current.yesterday)

        # default roles scope does not include ended roles
        expect(people(:top_leader).roles).to be_empty

        person = Person.preload_roles_unscoped.find(people(:top_leader).id)
        expect(person.roles).to be_loaded
        expect(person.roles).to have(1).item
      end

      it "preloading works when chained with other scopes" do
        person = Person.preload_roles_unscoped
          .where.not(id: nil)
          .where(id: people(:top_leader).id).first
        expect(person.roles).to be_loaded
        expect(person.roles).to have(1).item
      end
    end

    describe "preoload_roles" do
      it "preloads roles with custom scope" do
        Fabricate(Group::TopGroup::Secretary.sti_name,
          group: groups(:top_group),
          person: people(:top_leader))

        expect(people(:top_leader).roles).to have(2).items

        person = Person.preload_roles(Role.where(type: Group::TopGroup::Secretary.sti_name))
          .find(people(:top_leader).id)
        expect(person.roles).to be_loaded
        expect(person.roles).to have(1).item
      end
    end
  end

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

  it "can be saved with emoji" do
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

  it "#order_by_name orders people by company_name then last_name then first_name and then nickname" do
    Person.destroy_all
    Person.create!(company: true, company_name: "AA")
    Person.create!(company: true, company_name: "BA")
    Person.create!(company: false, last_name: "AB")
    Person.create!(company: false, last_name: "BB")
    Person.create!(company: false, first_name: "AC")
    Person.create!(company: false, first_name: "BC")
    Person.create!(company: false, nickname: "AD")
    Person.create!(company: false, nickname: "BD")

    # Checking order by name with hardcoded nickname prefixes
    expect(Person.order_by_name.select("*").collect(&:to_s)).to eq(["AA", "AB", "AC", " / AD", "BA", "BB", "BC", " / BD"].collect(&:to_s))
  end

  it "#order_by_name orders people with same last_name by first_name" do
    Person.destroy_all
    p1 = Person.create(last_name: "AA")
    p2 = Person.create(last_name: "BB", first_name: "BB")
    p3 = Person.create(last_name: "BB", first_name: "AA")
    p4 = Person.create(last_name: "CC")

    # Checking order by name with hardcoded nickname prefixes
    expect(Person.order_by_name.select("*").collect(&:to_s)).to eq([p1, p3, p2, p4].collect(&:to_s))
  end

  context "with one role" do
    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

    its(:layer_groups) { should == [groups(:top_layer)] }

    it "has layer_and_below_full permission in top_group" do
      expect(person.groups_with_permission(:layer_and_below_full)).to eq([groups(:top_group)])
    end

    it "found ended last role" do
      end_date = Date.current.yesterday
      expect(person.roles.count).to eq 1
      role.update(end_on: end_date)
      expect(person.roles.count).to eq 0
      expect(person.decorate.last_role.end_on).to eq(end_date)
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
      expect { person.destroy }.to change { Role.with_inactive.count }.by(-1)
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

    context "validation can be disabled" do
      # restore default configuration
      after { Person.validate_zip_code = true }

      it "on instance" do
        person.validate_zip_code = false
        person.zip_code = "hello world"
        expect(person).to be_valid
      end

      it "on class" do
        Person.validate_zip_code = false
        person.zip_code = "hello world"
        expect(person).to be_valid
      end
    end

    context "no country" do
      before do
        person.country = nil
      end

      it "it is valid with swiss zip_code" do
        person.zip_code = "1234"
        expect(person).to be_valid
      end

      it "it is invalid with german zip_code" do
        person.zip_code = "12345"
        expect(person).not_to be_valid
      end
    end

    context "switzerland" do
      before do
        person.country = :ch
      end

      ["1000", "1234", "3007", "9000"].each do |zip_code|
        it "should be valid with #{zip_code}" do
          person.zip_code = zip_code
          expect(person).to be_valid
        end
      end

      it "should allow empty plz" do
        person.zip_code = nil
        expect(person).to be_valid
      end

      ["10115", "01200", "3000 ", "99577-0727", "2597 GV 75", "C1420", "SW1W 0NY"].each do |zip_code|
        it "should not be valid with #{zip_code}" do
          person.zip_code = zip_code
          expect(person).not_to be_valid
        end
      end
    end

    context "foreign country" do
      context "germany" do
        before do
          person.country = :de
        end

        ["10000", "12345", "30077", "90000"].each do |zip_code|
          it "should be valid with #{zip_code}" do
            person.zip_code = zip_code
            expect(person).to be_valid
          end
        end

        it "should allow empty plz" do
          person.zip_code = nil
          expect(person).to be_valid
        end

        ["1011", "01200 ", "99577-0727", "2597 GV 75", "C1420", "SW1W 0NY"].each do |zip_code|
          it "should not be valid with #{zip_code}" do
            person.zip_code = zip_code
            expect(person).not_to be_valid
          end
        end
      end

      context "italy" do
        before do
          person.country = :de
        end

        ["10000", "12345", "30077", "90000"].each do |zip_code|
          it "should be valid with #{zip_code}" do
            person.zip_code = zip_code
            expect(person).to be_valid
          end
        end

        it "should allow empty plz" do
          person.zip_code = nil
          expect(person).to be_valid
        end

        ["1011", "01200 ", "99577-0727", "2597 GV 75", "C1420", "SW1W 0NY"].each do |zip_code|
          it "should not be valid with #{zip_code}" do
            person.zip_code = zip_code
            expect(person).not_to be_valid
          end
        end
      end

      context "netherlands" do
        before do
          person.country = :nl
        end

        ["1000 AP", "1204DT", "9271 JS", "1403BT", "2817 DG", "1028DH"].each do |zip_code|
          it "should be valid with #{zip_code}" do
            person.zip_code = zip_code
            expect(person).to be_valid
          end
        end

        it "should allow empty plz" do
          person.zip_code = nil
          expect(person).to be_valid
        end

        ["1011", "01200 ", "99577-0727", "2597 GV 75", "C1420", "SW1W 0NY"].each do |zip_code|
          it "should not be valid with #{zip_code}" do
            person.zip_code = zip_code
            expect(person).not_to be_valid
          end
        end
      end

      context "great britain" do
        before do
          person.country = :gb
        end

        ["SL6 2BL", "TS2 1DE", "DT9 6AL", "EN6 3HN", "TW19 6BX", "SW19 3RQ"].each do |zip_code|
          it "should be valid with #{zip_code}" do
            person.zip_code = zip_code
            expect(person).to be_valid
          end
        end

        it "should allow empty plz" do
          person.zip_code = nil
          expect(person).to be_valid
        end

        ["1011", "01200 ", "99577-0727", "2597 GV 75", "C1420"].each do |zip_code|
          it "should not be valid with #{zip_code}" do
            person.zip_code = zip_code
            expect(person).not_to be_valid
          end
        end
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
      Fabricate(:person, zip_code: "12000", country: "DE")
      list = Person.includes(:location).where("zip_code LIKE '%1200%'").order(:zip_code).to_a

      expect(list.first.location).to be_nil
      expect(list.second.location).to eq(l)
      expect(list.third.location).to be_nil
    end
  end

  describe "#finance_groups" do
    let(:person) { people(:top_leader) }

    it "returns uniq list of layer groups on which user has finance permission" do
      Fabricate(Group::TopLayer::TopAdmin.name.to_s, person: person, group: groups(:top_layer))
      allow_any_instance_of(Group::TopLayer::TopAdmin).to receive(:permissions)
        .and_return([:finance])
      expect(person.finance_groups).to eq [groups(:top_layer)]
    end
  end

  it "#filter_attrs returns list of filterable attributes" do
    attrs = Person.filter_attrs
    expect(attrs[:first_name]).to eq(label: "Vorname", type: :string)
    expect(attrs[:last_name]).to eq(label: "Nachname", type: :string)
    expect(attrs[:nickname]).to eq(label: "Übername", type: :string)
    expect(attrs[:company_name]).to eq(label: "Firmenname", type: :string)
    expect(attrs[:email]).to eq(label: "Haupt-E-Mail", type: :string)
    expect(attrs[:address_care_of]).to eq(label: "zusätzliche Adresszeile", type: :string)
    expect(attrs[:street]).to eq(label: "Strasse", type: :string)
    expect(attrs[:housenumber]).to eq(label: "Hausnummer", type: :string)
    expect(attrs[:postbox]).to eq(label: "Postfach", type: :string)
    expect(attrs[:zip_code]).to eq(label: "PLZ", type: :string)
    expect(attrs[:town]).to eq(label: "Ort", type: :string)
    expect(attrs[:country]).to eq(label: "Land", type: :string)
    expect(attrs[:gender]).to eq(label: "Geschlecht", type: :string)
    expect(attrs[:years]).to eq(label: "Alter", type: :integer)

    expect(Person.filter_attrs.count).to eq(Person::FILTER_ATTRS.count)
  end

  it "#filter_attrs is controlled by attributes define in Person::FILTER_ATTRS" do
    stub_const("Person::FILTER_ATTRS", [:first_name, [:active_years, :custom_type]])
    attrs = Person.filter_attrs
    expect(attrs[:first_name]).to eq(label: "Vorname", type: :string)
    expect(attrs[:active_years]).to eq(label: "Active years", type: :custom_type)
  end

  xdescribe "#picture" do
    let(:person) { Fabricate(:person) }

    before do
      person.picture.attach(
        io: File.open("spec/fixtures/person/test_picture.jpg"),
        filename: "test_picture.jpg"
      )
      person.picture.analyze
    end

    describe "default" do
      it "scales down an image to be exactly 32 by 32 pixels" do
        expect(person.picture.variant(:thumb).metadata).to be_nil # 32x32
      end
    end

    describe "#thumb" do
      it "scales down an image to be no wider than 512 pixels" do
        expect(person.picture).to have_dimensions(512, 512)
      end
    end
  end

  describe "#to_s" do
    let(:company) { false }
    let(:company_name) { nil }
    let(:person) { Fabricate.build(:person, first_name: "John", last_name: "Doe", nickname: "Jonny", company: company, company_name: company_name) }

    context "without company" do
      it "returns full name" do
        expect(person.to_s).to eq("John Doe / Jonny")
      end
    end

    context "with company" do
      let(:company) { true }

      context "without company name" do
        it "returns full name" do
          expect(person.to_s).to eq("John Doe / Jonny")
        end
      end

      context "with company name" do
        let(:company_name) { "FooCorp" }

        it "returns company name" do
          expect(person.to_s).to eq("FooCorp")
        end
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

    it "sends sentry notification if correct email is invalid" do
      allow(Truemail).to receive(:valid?).and_return(false)
      person.email = "dude@domainungueltig42.ch"

      expect(Raven).to receive(:capture_message)
        .exactly(:once)
        .with(
          "Truemail does not work as expected",
          extra: {
            verifier_email: Settings.root_email,
            validated_email: person.email
          }
        )

      expect(person).not_to be_valid
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
      person.update_columns(email: "not-an-email")
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
      person.additional_emails.first.email = "pushkar@vibha.org"
      person.save!

      expect(taggings.reload.count).to eq(0)
    end
  end

  describe "invalid address tags" do
    let(:person) { people(:bottom_member) }
    let(:taggings) do
      ActsAsTaggableOn::Tagging
        .where(taggable: person)
    end

    before { Contactable::AddressValidator.new.validate_people }

    it "removes invalid address tags when saving new address" do
      expect(taggings.count).to eq(1)

      person.street = "Belpstrasse"
      person.housenumber = "37"
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

  describe "with_address scope" do
    let(:top_leader) { people(:top_leader) }

    before do
      top_leader.update!(street: nil, housenumber: nil, zip_code: nil, town: "Supertown")
    end

    it "lists people with last_name, address, zip_code and town" do
      results = Person.with_address

      expect(results.count).to eq(1)
      expect(results).to include(people(:bottom_member))
    end

    it "lists no people with blank last_name or street" do
      people(:bottom_member).update!(last_name: "", street: "")

      results = Person.with_address

      expect(results.count).to eq(0)
    end

    it "lists no people with spaces for last_name or street" do
      people(:bottom_member).update!(last_name: "        ", street: "     ")

      results = Person.with_address

      expect(results.count).to eq(0)
    end

    it "lists people with company_name, street, zip_code and town" do
      people(:bottom_member).update!(last_name: nil, company_name: "Puzzle ITC")

      results = Person.with_address

      expect(results.count).to eq(1)
      expect(results).to include(people(:bottom_member))
    end

    it "lists no people with blank company_name or street" do
      people(:bottom_member).update!(last_name: nil, company_name: "", street: "")

      results = Person.with_address

      expect(results.count).to eq(0)
    end

    it "lists no people with spaces for company_name or street" do
      people(:bottom_member).update!(last_name: nil, company_name: "        ", street: "   ")

      results = Person.with_address

      expect(results.count).to eq(0)
    end
  end

  it "has a non-persisted shared_access_token" do
    person = Fabricate(:person)
    token = Devise.friendly_token

    expect(person).to respond_to(:shared_access_token)
    expect(person).to respond_to(:shared_access_token=)

    person.shared_access_token = token
    expect(person.shared_access_token).to eq token

    person = Person.find(person.id)
    expect(person.shared_access_token).to be_nil
  end

  describe "encrypted_two_fa_secret" do
    let(:person) { people(:bottom_member) }

    it "is being encrypted when generated" do
      person.two_fa_secret = People::OneTimePassword.generate_secret

      person.save!

      person.reload

      expect(person.encrypted_two_fa_secret).to_not be_nil
      expect(person.encrypted_two_fa_secret[:iv]).to_not be_nil
      expect(person.encrypted_two_fa_secret[:encrypted_value]).to_not be_nil
    end

    it "is being encrypted and correctly decrypted" do
      decrypted_secret = ROTP::Base32.random

      person.two_fa_secret = decrypted_secret

      person.save!

      person.reload

      expect(person.encrypted_two_fa_secret).to_not be_nil

      expect(person.two_fa_secret).to eq(decrypted_secret)
    end
  end

  describe "#language" do
    let(:person) { Person.new(last_name: "Foo") }

    it "is not valid with valid outside defined languages" do
      expect(person).to be_valid

      person.language = "rm"

      expect(person).to_not be_valid
    end
  end

  describe "#self_registration_reason" do
    let(:reason) { Fabricate(:self_registration_reason) }

    it "can be set on create" do
      person = Fabricate(:person, self_registration_reason: reason)
      expect(person.self_registration_reason).to eq reason
    end

    it "can not be set on update" do
      person = Fabricate(:person)
      expect { person.update(self_registration_reason: reason) }
        .not_to change { person.reload.self_registration_reason }.from(nil)
    end

    it "can not be changed on update" do
      person = Fabricate(:person, self_registration_reason: reason)
      new_reason = Fabricate(:self_registration_reason)
      expect { person.update(self_registration_reason: new_reason) }
        .not_to change { person.reload.self_registration_reason }.from(reason)
    end

    it "can not be cleared on update" do
      person = Fabricate(:person, self_registration_reason: reason)
      expect { person.update(self_registration_reason: nil) }
        .not_to change { person.reload.self_registration_reason }.from(reason)
    end
  end

  describe "#self_registration_reason_custom_text" do
    it "can be set on create" do
      person = Fabricate(:person, self_registration_reason_custom_text: "foo")
      expect(person.self_registration_reason_custom_text).to eq "foo"
    end

    it "can not be changed on update" do
      person = Fabricate(:person, self_registration_reason_custom_text: "foo")
      expect { person.update(self_registration_reason_custom_text: "bar") }
        .not_to change { person.reload.self_registration_reason_custom_text }.from("foo")
    end

    it "can not be cleared on update" do
      person = Fabricate(:person, self_registration_reason_custom_text: "foo")
      expect { person.update(self_registration_reason_custom_text: nil) }
        .not_to change { person.reload.self_registration_reason_custom_text }.from("foo")
    end

    it "can not be set if #self_registration_reason is set" do
      person = Person.new(
        self_registration_reason: Fabricate(:self_registration_reason),
        self_registration_reason_custom_text: "foo"
      )
      person.validate

      expect(person.errors[:self_registration_reason_custom_text])
        .to eq ["kann nicht gesetzt werden, wenn ein vordefinierter Eintrittsgrund ausgewählt wurde."]
    end
  end

  describe "#self_registration_reason_text" do
    it "returns #self_registration_reason.text if present" do
      reason = Fabricate.build(:self_registration_reason, text: "SelfRegistrationReason.text")
      person = Fabricate.build(:person, self_registration_reason: reason)
      expect(person.self_registration_reason_text).to eq "SelfRegistrationReason.text"
    end

    it "returns #self_registration_reason_custom_text if present" do
      person = Fabricate.build(:person, self_registration_reason_custom_text: "Person.self_registration_reason_custom_text")
      expect(person.self_registration_reason_text).to eq "Person.self_registration_reason_custom_text"
    end

    it "returns nil if neither #self_registration_reason nor #self_registration_reason_custom_text is present" do
      person = Fabricate.build(:person, self_registration_reason: nil, self_registration_reason_custom_text: nil)
      expect(person.self_registration_reason_text).to be_nil
    end
  end

  describe "#blocked?" do
    it "returns true if blocked_at is present" do
      person = Fabricate.build(:person, blocked_at: Time.zone.now)
      expect(person.blocked?).to be_truthy
      expect(person.login_status).to eq(:blocked)
    end

    it "returns false if blocked_at is blank" do
      person = Fabricate.build(:person, blocked_at: nil)
      expect(person.blocked?).to be_falsey
    end
  end

  describe "after update" do
    let(:person) { people(:top_leader) }

    it "schedules duplicate locator job after updating duplication related attributes" do
      expect(Person::DuplicateLocatorJob).to receive(:new)
        .with(person.id)
        .and_call_original

      expect do
        person.update!(first_name: "Hansli", last_name: "Miller")
      end.to change {
        Delayed::Job
          .where(Delayed::Job
          .arel_table[:handler]
          .matches("%Person::DuplicateLocatorJob%"))
          .count
      }.by(1)
    end

    it "does not schedule duplicate locator job if non relevant attributes are updated" do
      expect(Person::DuplicateLocatorJob).to receive(:new)
        .with(person.id)
        .never

      person.update!(nickname: "Hellboy")
    end
  end

  describe "membership_verify_token" do
    let(:person) { people(:top_leader) }

    it "sets token on first access" do
      token = person.membership_verify_token

      expect(token.length).to eq(24)
      expect(Person.find_by(membership_verify_token: token)).to eq(person)
    end

    it "creates other token if token is taken already" do
      token = person.membership_verify_token
      other_person = Fabricate(:person)
      other_token = "other-sweet-token"

      expect(SecureRandom).to receive(:base58).and_return(token)
      expect(SecureRandom).to receive(:base58).and_return(other_token)

      expect(other_person.membership_verify_token).to eq(other_token)
    end

    it "is not possible to set token manually" do
      token = person.membership_verify_token
      other_person = Fabricate(:person)
      other_person.update!(membership_verify_token: token)

      expect(other_person.membership_verify_token).not_to eq(token)
    end
  end
end
