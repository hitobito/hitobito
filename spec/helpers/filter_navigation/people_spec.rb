# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe 'FilterNavigation::People' do

  let(:template) do
    double('template').tap do |t|
      t.stub(can?: true)
      t.stub(group_people_path: 'people_path')
      t.stub(group_people_filter_path: 'people_filter_path')
      t.stub(new_group_people_filter_path: 'new_people_filter_path')
      t.stub(link_action_destroy: '<a destroy>')
      t.stub(icon: '<i>')
      t.stub(ti: 'delete')
      t.stub(:link_to) { |label, path| "<a href='#{path}'>#{label}</a>" }
      t.stub(:content_tag) { |tag, content, options| "<#{tag} #{options.inspect}>#{content}</#{tag}>" }
    end
  end

  subject { FilterNavigation::People.new(template, group, nil, nil, nil) }

  context 'top layer' do
    let(:group) { groups(:top_layer).decorate }

    let(:role_types) do
      [Group::TopGroup::Leader.sti_name,
       Group::BottomLayer::Leader.sti_name]
    end

    context 'without params' do

      its(:main_items)      { should have(1).item }
      its(:active_label)    { should == 'Mitglieder' }
      its('dropdown.active') { should be_false }
      its('dropdown.label')  { should == 'Weitere Ansichten' }
      its('dropdown.items')  { should have(3).items }

      it 'contains external item with count' do
        subject.main_items.last.should match(/Externe \(0\)/)
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

        its('dropdown.active') { should be_false }
        its('dropdown.label')  { should == 'Weitere Ansichten' }
        its('dropdown.items')  { should have(4).items }

      end
    end

    context 'with selected filter' do

      before do
        group.people_filters.create!(name: 'Leaders',
                                     role_types: role_types)
      end

      subject { FilterNavigation::People.new(template, group, 'Leaders', role_types, nil) }

      its(:main_items)      { should have(1).items }
      its(:active_label)    { should == nil }
      its('dropdown.active') { should be_true }
      its('dropdown.label')  { should == 'Leaders' }
      its('dropdown.items')  { should have(4).item }

    end
  end

  context 'bottom layer' do
    let(:group) { groups(:bottom_layer_one).decorate }

    it 'contains member item with count' do
      subject.main_items.first.should match(/Mitglieder \(1\)/)
    end

    it 'contains external item with count' do
      subject.main_items.last.should match(/Externe \(0\)/)
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
      subject.main_items.first.should match(/Mitglieder \(0\)/)
    end

    it 'contains external item with count' do
      subject.main_items.last.should match(/Externe \(0\)/)
    end
  end
end
