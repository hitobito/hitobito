# frozen_string_literal: true

#  Copyright (c) 2023, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
migration_file_name = Dir[Rails.root.join('db/migrate/20230615084630_add_last_active_role_to_people.rb')].first
require migration_file_name


describe AddLastActiveRoleToPeople do

  before(:all) { self.use_transactional_tests = false }
  after(:all)  { self.use_transactional_tests = true }

  let(:migration) { described_class.new.tap { |m| m.verbose = false } }

  after do
    Person.delete_all
  end

  context '#up' do
    let!(:people_without_active_roles) do
      10.times.collect do
        person = Fabricate(Group::BottomLayer::Member.sti_name.to_sym,
                           created_at: 1.month.ago, deleted_at: 2.weeks.ago,
                           group: groups(:bottom_layer_one)).person

        Fabricate(Group::BottomLayer::LocalGuide.sti_name.to_sym,
                  created_at: 1.month.ago, deleted_at: 1.week.ago,
                  group: groups(:bottom_layer_one),
                  person: person)
        person
      end
    end

    let!(:people_with_active_roles) do
      10.times.collect do
        Fabricate(Group::BottomLayer::Member.sti_name.to_sym,
                  created_at: 1.month.ago,
                  group: groups(:bottom_layer_one)).person
      end
    end

    before do
      migration.down
    end

    it 'assigns last_active_role' do
      migration.up

      people_without_active_roles.each do |p|
        p.reload
        expect(p.last_active_role_id).to be_present

        last_active_role = p.last_active_role
        expect(last_active_role.type).to eq(Group::BottomLayer::LocalGuide.sti_name)
        expect(last_active_role.deleted_at).to be_within(10.seconds).of(1.week.ago)
      end

      people_with_active_roles.each do |p|
        p.reload
        expect(p.last_active_role_id).to be_nil
      end
    end
  end
end
