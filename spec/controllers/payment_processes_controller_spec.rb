#  Copyright (c) 2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'


describe PaymentProcessesController do

  let(:invoice)        { invoices(:sent) }
  let(:group)          { invoice.group }

  before { sign_in(people(:bottom_member)) }

  it 'GET#new renders fileupload prompt' do
    get :new, params: { group_id: group.id }
    expect(response).to be_successful
  end

  it 'POST#create redirects if file has wrong media_type' do
    post :create, params: { group_id: group.id, payment_process: { file: file(media_type: 'text/plain') } }
    expect(response).to redirect_to new_group_payment_process_path(group)
    expect(flash[:alert]).to be_present
  end

  it 'POST#create redirects if file has bad payload' do
    post :create, params: { group_id: group.id, payment_process: { file: file(path: xmlfile('FI_camt_053_sample')) } }
    expect(response).to redirect_to new_group_payment_process_path(group)
    expect(flash[:alert]).to be_present
  end

  it 'POST#create handles files with only one entry' do
    post :create, params: { group_id: group.id, payment_process: { file: file(path: xmlfile('FI_camt_single_entry')) } }
    expect(response).to be_successful
    expect(flash[:alert]).to be_blank
    expect(flash[:notice]).to be_blank
  end

  it 'POST#create with file informs about valid and invalid payments' do
    invoice.update_columns(esr_number: '00 00000 00000 10000 00000 00905')
    post :create, params: { group_id: group.id, payment_process: { file: file } }
    expect(response).to be_successful
    expect(flash[:alert]).to be_present
    expect(flash[:notice]).to be_present
  end

  it 'POST#create with data persists valid payments' do
    invoice.update_columns(esr_number: '00 00000 00000 10000 00000 00905')
    expect do
      post :create, params: { group_id: group.id, data: xmlfile.read }
    end.to change { invoice.payments.count }.by(1)
    expect(response).to redirect_to group_invoices_path(group)
    expect(invoice.reload).to be_payed
  end

  private

  def file(path: xmlfile, media_type:  'text/xml')
    Rack::Test::UploadedFile.new(path, media_type)
  end

  def xmlfile(name = 'camt.054-ESR-ASR_T_CH0209000000857876452_378159670_0_2018031411011923')
    Rails.root.join("spec/fixtures/invoices/#{name}.xml")
  end

end
