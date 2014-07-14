# encoding: utf-8

#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe ApplicationSerializer do

  class TestPersonSerializer < ApplicationSerializer
    schema do
      json_api_properties

      map_properties :first_name, :last_name

      apply_extensions(:details)

      # entities with content appearing multiple times
      entity :primary_group, item.primary_group do |group, s|
        s.json_api_properties
        s.property :name, group.name
      end
      # additional property to test unify_linked_entries
      entity :default_group, item.primary_group do |group, s|
        s.json_api_properties
        s.property :name, group.name
      end

      # entity containing only id
      entities :roles, item.roles do |role, s|
        s.json_api_properties
      end

      template_link(:primary_group, 'groups', '/groups/%7Bprimary_group%7D', returning: true)

      modification_properties
    end

    extension(:details) do
      map_properties :town
    end

    extension(:other) do
      map_properties :country
    end

    extension(:details) do
      map_properties :email
    end
  end

  let(:person) do
    p = people(:top_leader)
    p.update!(creator_id: p.id)
    p
  end

  let(:controller) { double().as_null_object }

  let(:serializer) { TestPersonSerializer.new(person, controller: controller)}
  let(:hash) { serializer.to_hash }

  subject { hash[:people].first }

  context 'format' do
    it 'contains plural main key with one entry' do
      hash.should have_key(:people)
      hash[:people].should have(1).item
    end
  end


  context '#extensions' do
    it 'contains all extension properties' do
      should have_key(:town)
      should have_key(:email)
      should_not have_key(:country)
    end
  end

  context '#json_api_properties' do
    it 'contains id as string' do
      subject[:id].should eq(person.id.to_s)
    end

    it 'contains plural type' do
      subject[:type].should eq('people')
    end
  end

  context '#modification_properties' do
    it 'contains created_at and updated_at' do
      subject[:created_at].should be_kind_of(Time)
      subject[:updated_at].should be_kind_of(Time)
    end

    it 'contains creator_id and updater_id' do
      subject[:links][:creator].should eq(person.id.to_s)
      subject[:links][:updater].should be_nil
    end

    it 'contains links for creator and updater' do
      hash[:links]['people.creator'].should have_key(:href)
      hash[:links]['people.creator'][:type].should eq('people')
      hash[:links]['people.updater'].should have_key(:href)
      hash[:links]['people.updater'][:type].should eq('people')
    end
  end

  context '#template_link' do
    it 'are added to top level links' do
      hash[:links][:primary_group][:type].should eq('groups')
      hash[:links][:primary_group][:href].should eq('/groups/{primary_group}')
      hash[:links][:primary_group][:returning].should eq(true)
    end
  end

  context '#unify_linked_entities' do
    context 'with attributes' do
      it 'contains linked entries only once' do
        hash[:linked]['groups'].should have(1).item
      end

      it 'contains link data' do
        group = hash[:linked]['groups'].first
        group[:id].should eq(person.primary_group_id.to_s)
        group[:name].should eq('TopGroup')
      end

      it 'contains only ids in item links' do
        subject[:links][:primary_group].should eq(person.primary_group_id.to_s)
        subject[:links][:default_group].should eq(person.primary_group_id.to_s)
      end
    end

    context 'without attributes' do
      it 'contains only ids in item links' do
        subject[:links][:roles].should eq([person.roles.first.id.to_s])
      end

      it 'does not contain linked entries' do
        hash[:linked].should_not have_key('roles')
      end
    end
  end
end
