# encoding: utf-8
# == Schema Information
#
# Table name: people
#
#  id                     :integer          not null, primary key
#  first_name             :string(255)
#  last_name              :string(255)
#  company_name           :string(255)
#  nickname               :string(255)
#  company                :boolean          default(FALSE), not null
#  email                  :string(255)
#  address                :string(1024)
#  zip_code               :integer
#  town                   :string(255)
#  country                :string(255)
#  gender                 :string(1)
#  birthday               :date
#  additional_information :text
#  contact_data_visible   :boolean          default(FALSE), not null
#  created_at             :datetime
#  updated_at             :datetime
#  encrypted_password     :string(255)
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  picture                :string(255)
#  last_label_format_id   :integer
#  creator_id             :integer
#  updater_id             :integer
#  primary_group_id       :integer
#  failed_attempts        :integer          default(0)
#  locked_at              :datetime
#  authentication_token   :string(255)
#

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
require 'spec_helper'

describe Person do

  let(:person) { role.person.reload }
  subject { person }

  it 'is not valid without any names' do
    Person.new.should have(1).errors_on(:base)
  end

  it 'company only with nickname is not valid' do
    Person.new(company: true, nickname: 'foo').should have(1).errors_on(:company_name)
  end

  it 'company only with company name is valid' do
    p = Person.new(company: true, company_name: 'foo').should be_valid
  end

  it 'real only with nickname is valid' do
    Person.new(company: false, nickname: 'foo').should be_valid
  end

  it 'real only with company_name is not valid' do
    Person.new(company: false, company_name: 'foo').should have(1).errors_on(:base)
  end

  it 'with login role does not require email' do
    group = groups(:top_group)
    person = Person.new(last_name: 'Foo')

    person.should be_valid

    role = Group::TopGroup::Member.new
    role.group_id = group.id
    person.roles << role

    person.should have(0).error_on(:email)
  end

  it 'can create person with role' do
    group = groups(:top_group)
    person = Person.new(last_name: 'Foo', email: 'foo@example.com')
    role = group.class.role_types.first.new
    role.group_id = group.id
    person.roles << role

    person.save.should be_true
  end

  it '#order_by_name orders people by company_name or last_name' do
    Person.destroy_all
    p1 = Fabricate(:person, company: true, company_name: 'ZZ', last_name: 'AA')
    p2 = Fabricate(:person, company: false, company_name: 'ZZ', first_name: 'ZZ', last_name: 'BB')
    p3 = Fabricate(:person, company: true, company_name: 'AA', last_name: 'ZZ')
    p4 = Fabricate(:person, company: false, first_name: 'AA', last_name: 'BB')

    Person.order_by_name.collect(&:to_s).should == [p3, p4, p2, p1].collect(&:to_s)
  end

  context 'with one role' do
    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

    its(:layer_groups) { should == [groups(:top_layer)] }

    it 'has layer_and_below_full permission in top_group' do
      person.groups_with_permission(:layer_and_below_full).should == [groups(:top_group)]
    end
  end


  context 'with multiple roles in same layer' do
    let(:role) do
       role1 = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one))
       Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one), person: role1.person)
    end

    its(:layer_groups) { should == [groups(:bottom_layer_one)] }

    it 'has layer_and_below_full permission in top_group' do
      person.groups_with_permission(:layer_and_below_full).should == [groups(:bottom_layer_one)]
    end

    it 'has no layer_and_below_read permission' do
      person.groups_with_permission(:layer_and_below_read).should be_empty
    end

    it 'only layer role is visible from above' do
      person.groups_where_visible_from_above.should == [groups(:bottom_layer_one)]
    end

    it 'is not visible from above for bottom group' do
      g = groups(:bottom_group_one_one)
      g.people.visible_from_above(g).should_not include(person)
    end

    it 'is visible from above for bottom layer' do
      g = groups(:bottom_layer_one)
      g.people.visible_from_above(g).should include(person)
    end

    it 'preloads groups with the given scope' do
      p = Person.preload_groups.find(person.id)
      p.groups.should be_loaded
      p.groups.to_set.should == [groups(:bottom_group_one_one), groups(:bottom_layer_one)].to_set
    end

    it 'preloads roles with the given scope' do
      p = Person.preload_groups.find(person.id)
      p.roles.should be_loaded
      p.roles.first.association(:group).should be_loaded
    end

    it 'in_layer returns person for this layer' do
      Person.in_layer(groups(:bottom_group_one_one)).should =~ [people(:bottom_member), person]
    end

    it 'in_or_below returns person for above layer' do
      Person.in_or_below(groups(:top_layer)).should =~ [people(:bottom_member), people(:top_leader), person]
    end
  end

  context 'with multiple roles in different layers' do
    let(:role) do
       role1 = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group))
       Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one), person: role1.person)
    end

    its(:layer_groups) { should have(2).items }
    its(:layer_groups) { should include(groups(:top_layer), groups(:bottom_layer_one)) }

    it 'has contact_data permission in both groups' do
      person.groups_with_permission(:contact_data).should =~ [groups(:top_group), groups(:bottom_layer_one)]
    end

    it 'both groups are visible from above' do
      person.groups_where_visible_from_above.should =~ [groups(:top_group), groups(:bottom_layer_one)]
    end

    it 'whole hierarchy may view this person' do
      person.above_groups_where_visible_from.should =~ [groups(:top_layer), groups(:top_group), groups(:bottom_layer_one)]
    end

    it 'in_layer returns person for this layer' do
      Person.in_layer(groups(:bottom_group_one_one)).should =~ [people(:bottom_member), person]
    end

    it 'in_or_below returns person for any layer' do
      Person.in_or_below(groups(:top_layer)).should =~ [people(:bottom_member), people(:top_leader), person]
    end
  end

  context 'with invisible role' do
    let(:group) { groups(:bottom_group_one_one) }
    let(:role) { Fabricate(Group::BottomGroup::Member.name.to_sym, group: group) }

    it 'has not role that is visible from above' do
      person.groups_where_visible_from_above.should be_empty
    end

    it 'is not visible from above without arguments' do
      group.people.visible_from_above.should_not include(person)
    end

    it 'is not visible from above without arguments' do
      group.people.visible_from_above(group).should_not include(person)
    end

    it 'is not visible from above in combination with other scopes' do
      Person.in_or_below(groups(:top_layer)).visible_from_above.should_not include(person)
    end
  end

  context 'devise recoverable' do
    let(:group) { groups(:bottom_group_one_one) }
    let(:person) { Fabricate(Group::BottomGroup::Member.name.to_sym, group: group).person.reload }

    it 'can reset password' do
      expect { person.send_reset_password_instructions }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end
  end

  context 'finders on participations' do
    let(:group) { groups(:top_layer) }
    let(:person) { people(:top_leader) }
    let(:course) { Fabricate(:course, groups: [groups(:top_layer)]) }

    it '.pending_applications returns events that are not active' do
      participation = Fabricate(:event_participation, person: people(:top_leader))
      application = Fabricate(:event_application, priority_1: course, participation: participation)
      person.pending_applications.should eq [application]
    end

    it '.upcoming_events returns events that are active' do
      course.dates.build(start_at: 2.days.from_now, finish_at: 5.days.from_now)
      course.save
      participation = Fabricate(:event_participation, event: course, person: people(:top_leader), active: true)
      person.upcoming_events.should eq [course]
    end
  end

  context 'email validation' do
    it 'can create two people with empty email' do
      expect { 2.times { Fabricate(:person, email: '') }  }.to change { Person.count }.by(2)
    end

    it 'cannot create two people same email' do
      expect { 2.times { Fabricate(:person, email: 'foo@bar.com') }  }.to raise_error
    end
  end

  context 'all roles' do

    it 'all group roles ordered by group, to date' do
      person = Fabricate(:person)
      r1 = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one), person: person)
      r2 = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_two_one), person: person, created_at: Date.today - 3.years, deleted_at: Date.today - 2.years)
      r3 = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_two_one), person: person)

      person.all_roles.should == [r1, r3, r2]
    end
  end

  context '#ignored_country?' do
    it 'ignores ch, schweiz' do
      person = Person.new(country: 'Schweiz')
      person.ignored_country?.should be_true
      person = Person.new(country: 'CH')
      person.ignored_country?.should be_true
    end

    it 'does not ignore other countries' do
      person = Person.new(country: 'USA')
      person.ignored_country?.should be_false
    end
  end

  context '#destroy' do
    it 'destroys all roles' do
      person = people(:top_leader)
      person.roles.first.update_attribute(:created_at, 2.years.ago)
      expect { person.destroy }.to change { Role.with_deleted.count }.by(-1)
    end
  end

  context '#save' do
    it 'does not save person with duplicate email even when validation fails' do
      person = Person.new
      person.first_name = 'Foo'
      person.email = people(:top_leader).email
      person.save(validate: false).should be_false
      person.errors[:email].should == ["ist bereits vergeben. Diese Adresse muss für alle " \
                                        "Personen eindeutig sein, da sie beim Login verwendet " \
                                        "wird. Du kannst jedoch unter 'Weitere E-Mails' " \
                                        "Adressen eintragen, welche bei anderen Personen als " \
                                        "Haupt-E-Mail vergeben sind (Die Haupt-E-Mail kann leer " \
                                        "gelassen werden).\n"]
    end
  end

  context '#generate_reset_password_token!' do
    it 'generates the same token as #send_reset_password_instructions' do
      person = people(:top_leader)

      token = person.generate_reset_password_token!
      enc = person.reload.reset_password_token
      enc.should be_present
      person.clear_reset_password_token!
      person.reload.reset_password_token.should be_nil

      # as we cannot seed the token generator, we just compare the sizes..
      person.send_reset_password_instructions.size.should == token.size
      person.reset_password_token.size.should == enc.size
    end
  end

  context 'paper trail', versioning: true do
    context 'stores person id in main id' do
      it 'on create' do
        p = nil
        expect do
          p = Person.new(first_name: 'Foo')
          p.save!
        end.to change { PaperTrail::Version.count }.by(1)

        v = PaperTrail::Version.order(:created_at).last
        v.event.should == 'create'
        v.main_id.should == p.id
      end
    end
  end

  context '.mailing_emails_for' do
    it 'contains main and additional mailing emails' do
      e1 = Fabricate(:additional_email, contactable: people(:top_leader), mailings: true)
      Fabricate(:additional_email, contactable: people(:bottom_member), mailings: false)
      Person.mailing_emails_for(Person.all).should =~ [
        'bottom_member@example.com',
        'hitobito@puzzle.ch',
        'top_leader@example.com',
        e1.email
      ]
    end

    it 'does not contain blank emails' do
      people(:bottom_member).update_attributes!(email: ' ')
      Person.mailing_emails_for(Person.all).should =~ [
        'hitobito@puzzle.ch',
        'top_leader@example.com'
      ]
    end
  end

  context '#years' do
    before { Time.zone.stub(now: Time.zone.parse('2014-03-01 11:19:50')) }

    it 'is nil if person has no birthday' do
      Person.new.years.should be_nil
    end

    [ ['2006-02-12', 8],
      ['2005-03-15', 8],
      ['2004-02-29', 10] ].each do |birthday, years|
       it "is #{years} years old if born on #{birthday}" do
         Person.new(birthday: birthday).years.should eq years
       end
     end
  end

end
