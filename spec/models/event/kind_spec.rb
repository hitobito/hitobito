require 'spec_helper'

describe Event::Kind do

  let(:slk) { event_kinds(:slk) }

  it 'does not destroy translations on soft destroy' do
    expect { slk.destroy }.not_to change { Event::Kind::Translation.count }
  end

  it 'does destroy translations on hard destroy' do
    expect { slk.destroy! }.to change { Event::Kind::Translation.count }.by(-1)
  end

end
