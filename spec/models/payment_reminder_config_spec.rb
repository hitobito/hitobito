require "spec_helper"

describe PaymentReminderConfig do
  it "builds defaults for level 1" do
    subject.with_defaults(1)
    expect(subject.title).to eq "Zahlungserinnerung"
    expect(subject.text).to start_with "Im hektischen Alltag"
    expect(subject.due_days).to eq 30
  end

  it "builds defaults for level 2" do
    subject.with_defaults(2)
    expect(subject.title).to eq "Zweite Mahnung"
    expect(subject.text).to start_with "Trotz unserer Zahlungserinnerung"
    expect(subject.due_days).to eq 14
  end

  it "builds defaults for level 3" do
    subject.with_defaults(3)
    expect(subject.title).to eq "Dritte Mahnung"
    expect(subject.text).to start_with "Wir fordern Sie nun ein letztes Mal auf"
    expect(subject.due_days).to eq 5
  end

  it "raises for invalid level" do
    expect { subject.with_defaults(-1) }.to raise_error KeyError
  end
end
