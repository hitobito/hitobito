# frozen_string_literal: true

#  Copyright (c) 2012-2023, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe GroupDecorator, :draper_with_helpers do
  include Rails.application.routes.url_helpers

  let(:context) { double('context') }
  let(:model) { groups(:top_group) }

  subject { GroupDecorator.new(model) }

  describe 'possible roles' do
    its(:possible_roles) do
      should eq [
        Role::External,
        Group::TopGroup::GroupManager,
        Group::TopGroup::InvisiblePeopleManager,
        Group::TopGroup::Leader,
        Group::TopGroup::LocalGuide,
        Group::TopGroup::LocalSecretary,
        Group::TopGroup::Member,
        Group::TopGroup::Secretary
      ]
    end
  end

  context 'Top Group Roles' do
    let(:group) { groups(:top_group) }

    it 'sorts the list alphabetically by label' do
      common_arguments = { count: 1, scope: [:activerecord, :models] }

      [[:'group/top_group/leader', 'Leader', 'X'],
       [:'group/top_group/local_guide', 'Local guide', 'F'],
       [:'group/top_group/secretary', 'Secretary', 'D'],
       [:'group/top_group/local_secretary', 'Local secretary', 'L'],
       [:'group/top_group/group_manager', 'Group manager', 'E'],
       [:'group/top_group/member', 'Member', 'M'],
       [:'group/top_group/invisible_people_manager', 'Invisible people manager', 'G'],
       [:'role/external', 'External', 'H']].each do |class_path, class_name, sort_key|
        expect(I18n).to receive(:translate).with(class_path,
                                                 { default: [:role,
                                                             class_name] }.merge(common_arguments))
                                           .twice.and_return(sort_key)
      end

      expected_role_list_label = %w(D E F G H L M X)
      expected_role_list_class = %w(Group::TopGroup::Secretary Group::TopGroup::GroupManager
                                    Group::TopGroup::LocalGuide
                                    Group::TopGroup::InvisiblePeopleManager
                                    Role::External
                                    Group::TopGroup::LocalSecretary
                                    Group::TopGroup::Member
                                    Group::TopGroup::Leader)

      role_types = subject.role_types
      expect(role_types.map(&:label)).to eq(expected_role_list_label)
      expect(role_types.map(&:name)).to eq(expected_role_list_class)
    end
  end

  describe 'allowed_roles_for_self_registration' do
    its(:allowed_roles_for_self_registration) do
      should eq [Role::External,
                 Group::TopGroup::LocalSecretary,
                 Group::TopGroup::Member]
    end

    describe 'allowed_roles_for_self_registration in a bottom group' do
      let(:model) { groups(:bottom_group_one_one) }

      it 'should include roles which are not visible_from_above' do
        expect(subject.allowed_roles_for_self_registration).to eq [
          Role::External, Group::BottomGroup::Member
        ]
      end
    end
  end

  describe 'supports_self_registration?' do
    it 'returns true if it has any allowed_roles_for_self_registration' do
      allow(subject).to receive(:allowed_roles_for_self_registration).and_return([double])
      expect(subject.supports_self_registration?).to be true
    end

    it 'returns false if it has no allowed_roles_for_self_registration' do
      allow(subject).to receive(:allowed_roles_for_self_registration).and_return([])
      expect(subject.supports_self_registration?).to be false
    end
  end

  describe 'selecting attributes' do
    class DummyGroup < Group # rubocop:disable Lint/ConstantDefinitionInBlock
      self.used_attributes += [:foo, :bar]
    end

    let(:model) { DummyGroup.new }

    before do
      allow(subject).to receive_messages(h: context)
    end

    it '#used_attributes selects via .attr_used?' do
      expect(subject.used_attributes(:foo, :bar)).to eq %w(foo bar)
    end

    it '#modifiable_attributes we can :modify_superior' do
      expect(context).to receive(:can?).with(:modify_superior, subject).and_return(true)
      expect(subject.modifiable_attributes(:foo, :bar)).to eq %w(foo bar)
    end

    it '#modifiable_attributes filters attributes if we cannot :modify_superior' do
      allow(model.class).to receive_messages(superior_attributes: [:foo])
      expect(context).to receive(:can?).with(:modify_superior, subject).and_return(false)
      expect(subject.modifiable_attributes(:foo, :bar)).to eq %w(bar)
    end

    it '#modifiable? we can :modify_superior' do
      expect(context).to receive(:can?).with(:modify_superior, subject).and_return(true)
      expect(subject.modifiable?(:foo) { |val| val }).to eq %w(foo)
    end

    it '#modifiable? filters attributes if we cannot :modify_superior' do
      allow(model.class).to receive_messages(superior_attributes: [:foo])
      expect(context).to receive(:can?).with(:modify_superior, subject).and_return(false)
      expect(subject.modifiable_attributes(:foo) { |val| val }).to eq %w()
    end
  end

  describe 'subgroups' do
    let(:model) { groups(:bottom_layer_one) }

    its(:subgroup_ids) do
      should match_array(
        [
          groups(:bottom_layer_one),
          groups(:bottom_group_one_one),
          groups(:bottom_group_one_one_one),
          groups(:bottom_group_one_two)
        ].collect(&:id)
      )
    end
  end

  describe 'primary_group_toggle_link' do
    let(:person) { people(:top_leader) }
    let(:html) { GroupDecorator.new(model).primary_group_toggle_link(person, model) }
    subject(:node) { Capybara::Node::Simple.new(html) }

    it 'renders link with icon and text' do
      expect(node).to have_link 'Hauptgruppe setzen'
      expect(node).to have_css 'a i.fas.fa-star[filled=true]'
      expect(node.find('a')['href']).to eq(primary_group_group_person_path(model, person,
                                                                           primary_group_id: model.id))
    end
  end

  context 'archived groups' do
    let(:model) do
      groups(:bottom_group_one_two).tap { |g| g.update(archived_at: 1.day.ago) }
    end

    it 'suffix to_s' do
      expect(subject.to_s).to end_with(' (archiviert)')
    end

    it 'suffix to_s with argument' do
      expect(subject.to_s(:default)).to end_with(' (archiviert)')
    end

    it 'suffix to_s with argument' do
      expect(subject.to_s(:long_format)).to end_with(' (archiviert)')
    end

    it 'suffix display_name' do
      expect(subject.display_name).to end_with(' (archiviert)')
    end
  end

  context 'not archived groups' do
    let(:model) do
      groups(:bottom_group_one_two).tap { |g| g.update(archived_at: nil) }
    end

    it 'suffix to_s' do
      expect(subject.to_s).to_not end_with(' (archiviert)')
    end

    it 'suffix to_s with argument' do
      expect(subject.to_s(:default)).to_not end_with(' (archiviert)')
    end

    it 'suffix to_s with argument' do
      expect(subject.to_s(:long_format)).to_not end_with(' (archiviert)')
    end

    it 'suffix display_name' do
      expect(subject.display_name).to_not end_with(' (archiviert)')
    end
  end

  it 'reads the nextcloud_url from the next organizing group in the hierarchy' do
    expect(subject.nextcloud_url).to be_nil

    subject.layer_group.nextcloud_url = 'http://example.org'
    subject.layer_group.save!
    subject.reload

    expect(subject.nextcloud_organizer).to eq subject.layer_group
    expect(subject.nextcloud_organizer.nextcloud_url).to eq 'http://example.org'
  end
end
