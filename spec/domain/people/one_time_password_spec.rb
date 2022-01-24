# frozen_string_literal: true

# Copyright (c) 2021, hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https ://github.com/hitobito/hitobito.

require 'spec_helper'

describe People::OneTimePassword do
  let(:bottom_member) { people(:bottom_member) }
  let(:generate_token) { described_class.generate_secret }
  let(:totp_authenticator) { subject.send(:authenticator) }

  subject { described_class.new(@secret, person: @person) }

  context 'generate_secret' do
    it 'returns random Base32' do
      expect(ROTP::Base32).to receive(:random)

      generate_token
    end
  end

  context 'provisioning_uri' do
    it 'returns uri with person email' do
      @secret = described_class.generate_secret
      @person = bottom_member

      expect(subject.provisioning_uri).to include(ERB::Util.url_encode(bottom_member.email))
    end
  end

  context 'verify' do
    it 'returns nil if input token incorrect' do
      @secret = generate_token

      expect(subject.verify(totp_authenticator.now + '1')).to eq(nil)
    end

    it 'returns timestamp if input token correct' do
      @secret = generate_token

      expect(subject.verify(totp_authenticator.now)).to_not be_nil
    end
  end
end
