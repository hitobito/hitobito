# encoding: utf-8

#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
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
      allow(t).to receive_messages(edit_group_people_filter_path: 'edit_people_filter_path')
      allow(t).to receive_messages(new_group_people_filter_path: 'new_group_people_filter_path')
      allow(t).to receive_messages(link_action_destroy: '<a destroy>')
      allow(t).to receive_messages(icon: '<i>')
      allow(t).to receive_messages(ti: 'delete')
      allow(t).to receive_messages(t: 'global.link.edit')
      allow(t).to receive_messages(t: 'global.link.delete')
      allow(t).to receive_messages(safe_join: ["<i>", " ", "global.link.edit"])
      allow(t).to receive_messages(safe_join: ["<i>", " ", "global.link.delete"])
      allow(t).to receive(:link_to) { |label, path| "<a href='#{path}'>#{label}</a>" }
      allow(t).to receive(:content_tag) { |tag, content, options| "<#{tag} #{options.inspect}>#{content}</#{tag}>" }
    end
  end

  subject { FilterNavigation::People.new(template, group, Person::Filter::List.new(group, nil)) }

  context 'top layer' do
    let(:group) { groups(:top_layer).decorate }

    let(:role_types) do
      [Group::TopGroup::Leader,
       Group::BottomLayer::Leader]
    end

    context 'without params' do

      its(:main_items)      { should have(2).item }
      its(:active_label)    { should == 'Mitglieder' }
      its('dropdown.active') { should be_falsey }
      its('dropdown.label')  { should == 'Weitere Ansichten' }
      its('dropdown.items')  { should have(3).items }

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
          group.people_filters.create!(name: '2_Members',
                                       filter_chain: { role: { role_types: role_types.map(&:id) } })
          group.people_filters.create!(name: '1_Leaders',
                                       filter_chain: { role: { role_types: role_types.map(&:id) } })
        end

        its('dropdown.active') { should be_falsey }
        its('dropdown.label')  { should == 'Weitere Ansichten' }
        its('dropdown.items')  { should have(5).items }

        it 'has dropdown-items sorted by name' do
          expected_items = [
            'Gesamte Ebene',
            '1_Leaders',
            '2_Members',
            'Neuer Filter...'
          ]

          actual_items = subject.dropdown.items
            .select { |item| item.class == Dropdown::Item }
            .map(&:label)

          expect(actual_items).to match_array expected_items # all
          expect(actual_items).to eq expected_items          # in order
        end
      end
    end

    context 'with selected filter' do

      before do
        group.people_filters.create!(name: 'Leaders',
                                     filter_chain: { role: { role_types: role_types.map(&:id) } })
      end

      subject do
        filter = Person::Filter::List.new(group,
                                          nil,
                                          name: 'Leaders',
                                          filters: { role: { role_type_ids: role_types.map(&:id) } })
        FilterNavigation::People.new(template, group, filter)
      end

      its(:main_items)      { should have(2).items }
      its(:active_label)    { should == nil }
      its('dropdown.active') { should be_truthy }
      its('dropdown.label')  { should == 'Leaders' }
      its('dropdown.items')  { should have(4).item }

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

    its('dropdown.items')  { should have(3).items }

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
