# encoding: utf-8

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
describe 'person/security_tools/index.html.haml' do

  let(:top_group) { groups(:top_group) }
  let(:group) { groups(:bottom_layer_one) }
  let(:person) { people(:bottom_member) }
  let(:current_user) { people(:top_leader) }

  subject do
    person.touch(:last_sign_in_at)
    allow(controller).to receive_messages(current_user: current_user)
    allow(view).to receive_messages(parent: top_group, group: group, current_user: current_user,
                                    person: PersonDecorator.decorate(person))
    render
    Capybara::Node::Simple.new(@rendered)
  end

  context "with blocked user" do
    it 'shows the button to block user' do
      is_expected.to have_content I18n.t('person.security_tools.index.block_person')
    end
  end

  context "with blocked user" do
    before { Person::BlockService.new(person).block! }

    it 'shows the button to unblock user' do
      is_expected.to have_content I18n.t('person.security_tools.index.unblock_person')
    end
  end
end
