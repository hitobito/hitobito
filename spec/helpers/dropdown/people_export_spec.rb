# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe 'Dropdown::PeopleExport' do
  include Rails.application.routes.url_helpers


  include FormatHelper
  include LayoutHelper
  include UtilityHelper

  let(:user) { people(:top_leader) }
  let(:dropdown_options) do
    {
      households: true,
      labels: true
    }
  end
  let(:dropdown) do
    Dropdown::PeopleExport.new(
      self,
      user,
      { controller: 'people', group_id: groups(:top_group).id },
      **dropdown_options)
  end

  subject { Capybara::Node::Simple.new(dropdown.to_s) }

  def can?(*args)
    true
  end

  def menu
    subject.find('.btn-group > ul.dropdown-menu')
  end

  def top_menu_entries
    menu.all('> li > a').map(&:text)
  end

  def submenu_entries(name)
    menu.all("> li > a:contains('#{name}') ~ ul > li > a").map(&:text)
  end

  it 'renders dropdown' do
    is_expected.to have_content 'Export'
    is_expected.to have_selector '.btn-group > ul.dropdown-menu'

    expect(top_menu_entries).to match_array %w[CSV Excel vCard PDF Etiketten]

    expect(submenu_entries('CSV')).to match_array %w[Spaltenauswahl Adressliste Haushaltsliste]
    expect(submenu_entries('Etiketten')).to match_array [
                                                          "Envelope (C6, 1x1)",
                                                          "Haushalte zusammenfassen",
                                                          "Large (A4, 2x5)",
                                                          "Standard (A4, 3x10)"
                                                        ]
  end

  context 'mailchimp' do
    let(:dropdown_options) { {mailchimp_synchronization_path: 'asdf'} }

    it 'includes mailchimp if parameter is present' do
      expect(top_menu_entries).to include 'MailChimp'
    end
  end

  context 'email_adresses' do
    let(:dropdown_options) { {emails: true} }

    it 'includes email address entries if parameter is present' do
      expect(top_menu_entries).to include 'E-Mail Adressen'
      expect(top_menu_entries).to include 'E-Mail Adressen (Outlook)'
    end
  end

  context 'for global labels' do
    before :each do
      Fabricate(:label_format, name: 'SampleFormat')
    end

    it 'includes global formats if Person#show_global_label_formats is true' do
      user.update(show_global_label_formats: true)

      expect(submenu_entries('Etiketten')).to include 'SampleFormat (A4, 3x8)'
    end

    it 'excludes global formats if Person#show_global_label_formats is false' do
      user.update(show_global_label_formats: false)

      expect(submenu_entries('Etiketten')).not_to include 'SampleFormat (A4, 3x8)'
    end
  end
end
