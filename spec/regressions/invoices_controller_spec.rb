#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe InvoicesController, type: :controller do
  render_views

  let(:group) { groups(:bottom_layer_one) }
  let!(:sent) { invoices(:sent) }
  let(:letter) { messages(:with_invoice) }
  let(:invoice_list) { letter.create_invoice_list(title: "test", group_id: group.id) }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  before { sign_in(people(:bottom_member)) }

  describe "GET #show" do
    let!(:invoice) { invoices(:sent) }

    it "escapes recipient display" do
      invoice.update(recipient_address: "Hello <script>alert(1)</script>\nworld<script>alert(2)</script>", recipient_email: "test<script>alert(3)</script>@example.com")
      get :show, params: {group_id: group.id, invoice_list_id: invoice_list.id, id: invoice.id}
      recipient_address = dom.first(".address").native
      expect(recipient_address.inner_html).to match(/<p><b>Hello &lt;script&gt;alert\(1\)&lt;\/script&gt;<\/b><br>world&lt;script&gt;alert\(2\)&lt;\/script&gt;<br><a href="mailto:test%3Cscript%3Ealert%283%29%3C%2Fscript%3E@example\.com">test&lt;script&gt;alert\(3\)&lt;\/script&gt;@example\.com<\/a><\/p>/)
    end
  end
end
