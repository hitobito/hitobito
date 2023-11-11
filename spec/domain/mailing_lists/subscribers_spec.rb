#  Copyright (c) 2020, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


require 'spec_helper'

describe MailingLists::Subscribers do

  let(:subscribers) { described_class.new(mailing_list) }
  let(:mailing_list) { mailing_lists(:leaders) }

  describe '#people' do
    subject(:subscribers_people) { subscribers.people }
    let!(:top_leader) { people(:top_leader) }

    context 'without filter_chain' do
      pending
    end

    context 'with filter_chain' do
      pending
    end
  end
end
