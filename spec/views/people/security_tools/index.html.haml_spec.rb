# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
describe 'people/security_tools/index.html.haml' do

  let(:top_group) { groups(:top_group) }
  let(:group) { groups(:bottom_layer_one) }
  let(:person) { people(:bottom_member) }

  subject do
    allow(view).to receive_messages(current_user: current_user)
    allow(controller).to receive_messages(current_user: current_user)
    render
    Capybara::Node::Simple.new(@rendered)
  end

  before do
    # assign(:qualifications, [])
    assign(:group, group)
    allow(view).to receive_messages(parent: top_group)
    allow(view).to receive_messages(entry: PersonDecorator.decorate(person))
  end

    let(:current_user) { people(:top_leader) }

    it 'shows roles' do
      is_expected.to have_content 'Aktive Rollen'
    end

end
