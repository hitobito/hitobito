# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe MockDns do
  let(:dns) { Resolv::DNS.new }

  before do
    allow(UDPSocket).to receive(:new).and_call_original
    allow(TCPSocket).to receive(:new).and_call_original
  end

  def expect_no_dns_server_contacted
    expect(UDPSocket).not_to have_received(:new)
    expect(TCPSocket).not_to have_received(:new)
  end

  it "answers the mail server of a mail domain" do
    mx_records = dns.getresources("puzzle.ch", Resolv::DNS::Resource::IN::MX)

    expect(mx_records.map { |mx| mx.exchange.to_s }).to eq ["mail.puzzle.ch"]
    expect(dns.getaddress("mail.puzzle.ch").to_s).to eq "192.0.2.1"
    expect_no_dns_server_contacted
  end

  it "answers nothing for any other domain" do
    expect(dns.getresources("bluewin.com", Resolv::DNS::Resource::IN::MX)).to be_empty
    expect { dns.getaddress("bluewin.com") }.to raise_error(Resolv::ResolvError)
    expect_no_dns_server_contacted
  end

  it "answers the lookups of the Truemail validation" do
    allow(Truemail).to receive(:valid?).and_call_original

    expect(Truemail.valid?("dude@puzzle.ch")).to be true
    expect(Truemail.valid?("dude@bluewin.com")).to be false
    expect_no_dns_server_contacted
  end
end
