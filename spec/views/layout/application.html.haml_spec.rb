# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_die_mitte.


require 'spec_helper'
describe 'layouts/application.html.haml' do
  subject { Capybara::Node::Simple.new(rendered) }

  before do
    allow(controller).to receive(:current_person).and_return(person)
    allow(controller).to receive(:current_user).and_return(person)
    allow(controller).to receive(:origin_user).and_return(person)
    allow(view).to receive(:person_signed_in?).and_return(true)
    allow(view).to receive(:current_person).and_return(person)
    allow(view).to receive(:current_user).and_return(person)
    allow(view).to receive(:origin_user).and_return(person)
    allow(view).to receive(:person_home_path).and_return('')
  end

  context 'nav-left' do
    let(:person) { people(:top_leader) }

    it 'missing when user has no roles' do
      person.roles.destroy_all
      render
      expect(subject).not_to have_css('nav.nav-left')
    end

    it 'present when user has no roles but is root user' do
      person.roles.destroy_all
      allow(person).to receive(:root?).and_return(true)
      render
      expect(subject).to have_css('nav.nav-left')
    end

    it 'present when user has role' do
      render
      expect(subject).to have_css('nav.nav-left')
    end
  end
end
