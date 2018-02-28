# encoding: utf-8

#  Copyright (c) 2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#

require 'spec_helper'

describe Invoice::BatchUpdateResult do
  let(:draft) { invoices(:invoice) }
  let(:sent)  { invoices(:sent) }

  it 'tracks single invoice being issued' do
    subject.track_update(:issued, draft)
    expect(subject.notice).to eq ["Rechnung #{draft.sequence_number} wurde gestellt."]
  end

  it 'tracks multiple invoice being issued' do
    subject.track_update(:issued, draft)
    subject.track_update(:issued, sent)
    expect(subject.notice).to eq ['2 Rechnungen wurden gestellt.']
  end

  it 'tracks single invoice being sent' do
    subject.track_update(:issued, draft)
    subject.track_update(:send_notification, draft)
    expect(subject.notice).to eq ["Rechnung #{draft.sequence_number} wurde gestellt.",
                                  "Rechnung #{draft.sequence_number} wird im Hintergrund per E-Mail verschickt."]
  end

  it 'tracks multiple invoices being sent' do
    subject.track_update(:issued, draft)
    subject.track_update(:send_notification, draft)
    subject.track_update(:issued, sent)
    subject.track_update(:send_notification, sent)
    expect(subject.notice).to eq ['2 Rechnungen wurden gestellt.',
                                  '2 Rechnungen werden im Hintergrund per E-Mail verschickt.']
  end

end

