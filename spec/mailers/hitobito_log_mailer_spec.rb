# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe HitobitoLogMailer do
  let(:range) { 1.days.ago..Time.zone.now }

  before do
    Settings.hitobito_log.recipient_emails = ["it@hitobito.com", "test@hitobito.com"]
  end

  it "sends to every mail defined in hitobito log settings" do
    mail = described_class.error([HitobitoLogEntry.pluck(:id)], range)
    expect(mail.to).to match_array(["it@hitobito.com", "test@hitobito.com"])
  end

  context "with content" do
    before do
      custom_content = CustomContent.get(described_class::ERROR)
      custom_content.label = "Hitobito Log: Täglicher Fehlerbericht"
      custom_content.subject = "[Hitobito] Täglicher Fehlerbericht"
      custom_content.body = <<~HTML
        Guten Tag, <br><br>

        Dies ist die automatische Benachrichtigung über Fehler im <a href="{hitobito-log-url}">Hitobito Log</a>.

        Nachfolgend finden Sie die wichtigsten Informationen und eine Übersicht der ersten Fehler-Einträge der letzten 24 Stunden. <br>

        <strong>Anzahl Fehler</strong>: {error-count}<br>
        <strong>Zeitraum</strong>: {time-period} <br><br>
        <strong>Details zu den ersten 10 Fehler:</strong><br><br>
        {error-log-table}
      HTML
      custom_content.save!
    end

    it "renders for log entry for mailing list" do
      list = mailing_lists(:leaders)
      entry = HitobitoLogEntry.create!(subject: list, category: :mail, level: :error, message: :test)
      mail = described_class.error([entry.id], range)
      expect(mail.body).to match(%r{/mailing_lists/#{list.id}})
    end

    it "renders for payment provider config" do
      error_ebics = hitobito_log_entries(:error_ebics)
      error_ebics.update!(subject: payment_provider_configs(:postfinance))
      mail = described_class.error([error_ebics.id], range)
      expect(mail.body).to include '<a href="/de/hitobito_log_entries">Hitobito Log Einträge</a>'
    end
  end
end
