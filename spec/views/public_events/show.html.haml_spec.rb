#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
require "spec_helper"

describe "public_events/show.html.haml" do
  let(:group) { event.groups.first }
  let(:event) { EventDecorator.decorate(events(:top_event)) }

  before do
    assign(:event, event)
    assign(:group, group)
    allow(view).to receive_messages(entry: event, event:, group:, resource: Person.new,
      render_application_attrs?: true, render_login_forms?: true)
    allow(controller).to receive_messages(entry: event, current_user: nil, current_person: nil)
  end

  let(:dom) { Capybara::Node::Simple.new(raw(rendered)) }

  subject { dom }

  it "does not render external application link" do
    render
    expect(dom).not_to have_css "dt", text: "Externe Anmeldungen"
  end

  it "renders formatted description" do
    event.update!(description: "<div>Erste Zeile</div><div><a href=\"https://example.com\">Link</a></div>")
    render
    expect(dom).to have_css ".trix-content div", text: "Erste Zeile"
    expect(dom).to have_link "Link", href: "https://example.com"
  end
end
