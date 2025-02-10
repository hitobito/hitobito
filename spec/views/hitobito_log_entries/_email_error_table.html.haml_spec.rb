require "spec_helper"

describe "hitobito_log_entries/_email_error_table.html.haml" do
  # for specs we can use every level of log entries, doesnt change anything about the table in this case
  let(:log_entries) { HitobitoLogEntry.all }
  let(:dom) { Capybara::Node::Simple.new(@rendered) }

  before do
    render partial: "hitobito_log_entries/email_error_table", locals: {error_log_entries: log_entries}
  end

  it "renders the table headers correctly" do
    expect(dom).to have_selector("table")
    expect(dom).to have_selector("th", text: "Erstellt am")
    expect(dom).to have_selector("th", text: "Kategorie")
    expect(dom).to have_selector("th", text: "Subjekt")
    expect(dom).to have_selector("th", text: "Meldung")
    expect(dom).to have_selector("th", text: "Payload")
  end

  it "displays the correct number of log entries" do
    expect(dom).to have_selector("tbody tr", count: log_entries.count)
  end

  it "displays each log entries details" do
    log_entries.each do |entry|
      expect(dom).to have_text(I18n.l(entry.created_at))
      expect(dom).to have_text(entry.category)
      expect(dom).to have_text(entry.message)
    end
  end

  it "formats payload correctly if present" do
    entry_with_payload = log_entries.find { |entry| entry.payload.present? }
    expect(dom).to have_text(entry_with_payload.payload.to_json)
  end

  it "displays subject as link" do
    debug_subject = hitobito_log_entries(:debug_webhook).subject
    info_subject = hitobito_log_entries(:info_webhook).subject
    expect(dom).to have_link(debug_subject.to_s, href: polymorphic_path(debug_subject))
    expect(dom).to have_link(info_subject.to_s, href: polymorphic_path(info_subject))
  end
end
