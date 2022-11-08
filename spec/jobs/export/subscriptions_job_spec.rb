# frozen_string_literal: true

#  Copyright (c) 2017-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::SubscriptionsJob do

  subject do
    Export::SubscriptionsJob.new(format, user.id, mailing_list.id,
                                 export_options)
  end

  let(:export_options) do
    { household: household,
      show_related_roles_only: show_related_roles_only,
      filename: filename }
  end

  let(:mailing_list) { mailing_lists(:info) }
  let(:user) { people(:top_leader) }
  let(:filename) { AsyncDownloadFile.create_name('subscription_export', user.id) }
  let(:household) { true }
  let(:show_related_roles_only) { false }

  let(:group) { groups(:top_layer) }
  let(:mailing_list) { Fabricate(:mailing_list, group: group) }
  let(:file) { AsyncDownloadFile.from_filename(filename, format) }
  let(:lines) { file.read.lines }

  context 'export' do
    before do
      SeedFu.quiet = true
      SeedFu.seed [Rails.root.join('db', 'seeds')]

      Fabricate(:subscription, mailing_list: mailing_list)
      Fabricate(:subscription, mailing_list: mailing_list)
    end

    context 'creates an CSV-Export' do
      let(:format) { :csv }

      it 'and saves it' do
        subject.perform

        expect(lines.size).to eq(3)
        expect(lines[0]).to match(/Name;Adresse;.*/)
      end
    end

    context 'creates an Excel-Export' do
      let(:format) { :xlsx }

      it 'and saves it' do
        subject.perform

        expect(file.generated_file).to be_attached
      end
    end
  end

  context 'show related person roles only' do
    #
    # bottom layer two:
    #  - Bottom Member (Member)
    #  - Bottom Leader (Leader)
    # bottom group one one / Group 11:
    #  - Bottom Member (Leader)
    # bottom layer one:
    #  - Bottom Member (Leader)

    let(:mailing_list) { Fabricate(:mailing_list, group: groups(:top_layer)) }
    let(:format) { :csv }
    let(:role_cell_values) do
      lines.drop(1).collect { |l| l.split(';')[13] }.join(',').split(',').collect(&:strip)
    end
    let(:bottom_member) { people(:bottom_member) }
    let!(:bottom_leader) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two)).person }
    let(:show_related_roles_only) { true }
    let(:household) { false }

    before do
      Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two), person: bottom_member)
      Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one), person: bottom_member)

      Subscription.create!(mailing_list: mailing_list,
                          subscriber: groups(:bottom_layer_two),
                          role_types: [Group::BottomLayer::Leader])

      Subscription.create!(mailing_list: mailing_list,
                          subscriber: groups(:bottom_layer_one),
                          role_types: [Group::BottomLayer::Member])
    end

    it 'does only show subscription roles' do
      subject.perform

      expect(lines.size).to eq(3)
      expect(role_cell_values).not_to include('Leader Bottom One')
      expect(role_cell_values).not_to include('Member Bottom Two')
      expect(role_cell_values).to include('Leader Bottom Two')
      expect(role_cell_values).to include('Member Bottom One')
      expect(role_cell_values).not_to include('Leader Bottom One / Group 11')
    end

    it 'does show all roles if no group subscription' do
      mailing_list.subscriptions.destroy_all

      Subscription.create!(mailing_list: mailing_list,
                           subscriber: bottom_member)

      Subscription.create!(mailing_list: mailing_list,
                           subscriber: bottom_leader)

      subject.perform

      expect(lines.size).to eq(3)
      expect(role_cell_values).not_to include('Leader Bottom One')
      expect(role_cell_values).to include('Member Bottom One')
      expect(role_cell_values).to include('Leader Bottom Two')
      expect(role_cell_values).to include('Leader Bottom One / Group 11')
    end
  end

end
