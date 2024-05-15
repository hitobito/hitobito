#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe MailingListsHelper do

  include UtilityHelper
  include FormatHelper
  include LayoutHelper

  let(:entry) { mailing_lists(:leaders) }
  let(:current_user) { people(:top_leader) }

  describe '#format_mailing_list_name' do
    let(:dom) { Capybara::Node::Simple.new(format_mailing_list_name(entry)) }

    it 'renders name with link to messages path if user can update' do
      expect(self).to receive(:can?).with(:update, entry).and_return(true)
      expect(dom).to have_link 'Leaders', href: group_mailing_list_messages_path(entry.group, entry)
    end

    it 'renders name only if user cannot update' do
      expect(self).to receive(:can?).with(:update, entry).and_return(false)
      expect(dom).not_to have_link 'Leaders'
      expect(dom).to have_text 'Leaders'
    end
  end

  describe '#button_toggle_subscription' do
    it "with subscribed user shows 'Anmelden'" do
      sub = entry.subscriptions.new
      sub.subscriber = current_user
      sub.save!

      @group = entry.group
      expect(button_toggle_subscription).to match(/Abmelden/)
    end

    it "with not subscribed user shows 'Abmelden'" do
      @group = entry.group
      expect(button_toggle_subscription).to match(/Anmelden/)
    end
  end

end
