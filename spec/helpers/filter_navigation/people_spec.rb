# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe 'FilterNavigation::People' do

  let(:template) do
    double('template').tap do |t|
      allow(t).to receive_messages(can?: true)
      allow(t).to receive_messages(group_people_path: 'people_path')
      allow(t).to receive_messages(group_people_filter_path: 'people_filter_path')
      allow(t).to receive_messages(new_group_people_filter_path: 'new_group_people_filter_path')
      allow(t).to receive_messages(qualification_group_people_filters_path: 'qualification_group_people_filters_path')
      allow(t).to receive_messages(link_action_destroy: '<a destroy>')
      allow(t).to receive_messages(icon: '<i>')
      allow(t).to receive_messages(ti: 'delete')
      allow(t).to receive(:link_to) { |label, path| "<a href='#{path}'>#{label}</a>" }
      allow(t).to receive(:content_tag) { |tag, content, options| "<#{tag} #{options.inspect}>#{content}</#{tag}>" }
    end
  end

  subject { FilterNavigation::People.new(template, group, {}) }

  context 'top layer' do
    let(:group) { groups(:top_layer).decorate }

    let(:role_types) do
      [Group::TopGroup::Leader.sti_name,
       Group::BottomLayer::Leader.sti_name]
    end

    context 'without params' do

      its(:main_items)      { should have(1).item }
      its(:active_label)    { should == 'Mitglieder' }
      its('dropdown.active') { should be_falsey }
      its('dropdown.label')  { should == 'Weitere Ansichten' }
      its('dropdown.items')  { should have(4).items }

      it 'contains external item with count' do
        expect(subject.main_items.last).to match(/Externe \(0\)/)
      end

      it 'entire layer contains only layer role types' do
        subject.dropdown.items.first.url =~ /#{[Role::External,
                                                Group::GlobalGroup::Leader,
                                                Group::GlobalGroup::Member,
                                                Group::TopGroup::Leader,
                                                Group::TopGroup::Secretary,
                                                Group::TopGroup::Member].
                                               collect(&:id).join('-')}/
      end

      context 'with custom filters' do

        before do
          group.people_filters.create!(name: 'Leaders',
                                       role_types: role_types)
        end

        its('dropdown.active') { should be_falsey }
        its('dropdown.label')  { should == 'Weitere Ansichten' }
        its('dropdown.items')  { should have(5).items }

      end
    end

    context 'with selected filter' do

      before do
        group.people_filters.create!(name: 'Leaders',
                                     role_types: role_types)
      end

      subject { FilterNavigation::People.new(template, group, name: 'Leaders', role_type_ids: role_types) }

      its(:main_items)      { should have(1).items }
      its(:active_label)    { should == nil }
      its('dropdown.active') { should be_truthy }
      its('dropdown.label')  { should == 'Leaders' }
      its('dropdown.items')  { should have(5).item }

    end
  end

  context 'bottom layer' do
    let(:group) { groups(:bottom_layer_one).decorate }

    it 'contains member item with count' do
      expect(subject.main_items.first).to match(/Mitglieder \(1\)/)
    end

    it 'contains external item with count' do
      expect(subject.main_items.last).to match(/Externe \(0\)/)
    end
  end

  context 'bottom group' do
    let(:group) { groups(:bottom_group_one_one).decorate }

    it 'entire sub groups contains only sub groups role types' do
      subject.dropdown.items.first.url =~ /#{[Role::External,
                                              Group::GlobalGroup::Leader,
                                              Group::GlobalGroup::Member,
                                              Group::BottomGroup::Leader,
                                              Group::BottomGroup::Member].
                                             collect(&:id).join('-')}/
    end

    it 'contains member item with count' do
      expect(subject.main_items.first).to match(/Mitglieder \(0\)/)
    end

    it 'contains external item with count' do
      expect(subject.main_items.last).to match(/Externe \(0\)/)
    end
  end
end
