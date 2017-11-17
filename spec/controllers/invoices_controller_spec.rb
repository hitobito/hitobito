require 'spec_helper'

describe InvoicesController do

  let(:group) { groups(:bottom_layer_one) }
  let(:person) { people(:bottom_member) }

  context 'authorization' do
    before { sign_in(person) }

    it "may index when person has finance permission on layer group" do
      get :index, group_id: group.id
      expect(response).to be_success
    end

    it "may edit when person has finance permission on layer group" do
      invoice = Invoice.create!(group: group, title: 'test', recipient: person)
      get :edit, group_id: group.id, id: invoice.id
      expect(response).to be_success
    end

    it "may not index when person has finance permission on layer group" do
      expect do
        get :index, group_id: groups(:top_layer).id
      end.to raise_error(CanCan::AccessDenied)
    end

    it "may not edit when person has finance permission on layer group" do
      invoice = Invoice.create!(group: groups(:top_layer), title: 'test', recipient: person)
      expect do
        get :edit, group_id: groups(:top_layer).id, id: invoice.id
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  it 'DELETE#destroy moves invoice to cancelled state' do
    sign_in(person)

    invoice = Invoice.create!(group: group, title: 'test', recipient: person)
    expect do
      delete :destroy, group_id: group.id, id: invoice.id
    end.not_to change { group.invoices.count }
    expect(invoice.reload.state).to eq 'cancelled'
    expect(response).to redirect_to group_invoices_path(group)
    expect(flash[:notice]).to eq 'Rechnung wurde storniert.'
  end

end
