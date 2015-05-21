# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# encoding:  utf-8

require 'spec_helper'

describe RolesController, type: :controller do

  let(:test_entry) { roles(:bottom_member) }

  let(:new_entry_attrs) do
    {
      type: Group::BottomLayer::Member.sti_name
    }
  end

  let(:create_entry_attrs) do
    {
      label: 'Materialchef',
      type: Group::BottomLayer::Member.sti_name,
      person_id: people(:top_leader).id
    }
  end

  let(:test_entry_attrs) do
    {
      type: Group::BottomLayer::Member.sti_name,
      label: 'Materialchef'
    }
  end

  let(:group) { groups(:bottom_layer_one) }

  let(:scope_params) { { group_id: group.id } }


  before { sign_in(people(:top_leader)) }

  # Override a few methods to match the actual behavior.
  class << self
    def it_should_redirect_to_show
      it do |example|
        if example.metadata[:action] == :create
          is_expected.to redirect_to group_people_path(group.id)
        else
          is_expected.to redirect_to group_person_path(group.id, entry.person_id)
        end
      end
    end

    def it_should_redirect_to_index
      it do
        path = Role.where(id: entry.id).exists? ? person_path(entry.person_id) : group_path(group)
        is_expected.to redirect_to path
      end
    end
  end


  include_examples 'crud controller', skip: [%w(index), %w(show), %w(new plain)]


  describe_action :get, :new do
    context '.html', format: :html do
      it 'does not raise exception if no type is given' do
        expect(test_entry).to be_kind_of(Role)
      end

      context 'with invalid type' do
        let(:params) { { role: { type: 'foo' } } }

        it 'raises exception', perform_request: false do
          expect { perform_request }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

end
