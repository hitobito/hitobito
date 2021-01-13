# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require 'spec_helper'

describe Messages::DispatchesController do
  let(:message)    { messages(:letter) }
  let(:top_leader) { people(:top_leader) }

  before { sign_in(top_leader) }

  it 'POST#creates creates dispatch and enqueues job' do
    expect do
      post :create, params: { message_id: message.id }
    end.to change { Messages::DispatchJob.new(message).delayed_jobs.count }.by(1)
    expect(message.reload.state).to eq 'pending'
    expect(response).to redirect_to message.path_args
    expect(flash[:notice]).to eq 'Brief wurde als Druckauftrag vorbereitet.'
  end
end
