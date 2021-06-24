# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

require 'spec_helper'

describe 'locales' do
  context 'do not contain wrong spellings of "E-Mail":' do
    it 'Email' do
      expect(`grep 'Email' config/locales/*.de.yml | wc -l`.chomp.to_i).to be_zero
    end

    it 'e-mail' do
      expect(`grep 'e-mail' config/locales/*.de.yml | wc -l`.chomp.to_i).to be_zero
    end

    it 'e-Mail' do
      expect(`grep 'e-Mail' config/locales/*.de.yml | wc -l`.chomp.to_i).to be_zero
    end

    it 'email' do
      # the spelling "email" has a few false positives :-)
      email_lines = `grep -e ':.*email' config/locales/*.de.yml`
                    .split("\n").map(&:chomp)
                    .reject { |line| line =~ /.*Scope: email.*/ }
                    .reject { |line| line =~ /.*%{email}.*/ }

      expect(email_lines).to be_empty
    end
  end

  it 'do not contain wrong spellings of "Adresss":' do
    it 'Address' do
      expect(`grep Address config/locales/*.de.yml | wc -l`.chomp.to_i).to be_zero
    end
  end
end
