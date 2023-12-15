# encoding: utf-8

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::InactivityBlockMailer do

  describe '#inactivity_block_warning' do
    let(:recipient) { people(:bottom_member) }
    subject(:mail) { described_class.inactivity_block_warning(recipient) }

    it { expect(mail.to).to contain_exactly(recipient.email) }
    it { expect(mail.subject).to have_content("Login für hitobito von Top Leader wird bald blockiert") }
    it { expect(mail.body).to have_content("TBD") }
  end
end
