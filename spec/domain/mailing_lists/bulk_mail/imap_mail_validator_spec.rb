# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

require 'spec_helper'

describe MailingLists::BulkMail::ImapMailValidator do

  describe '#valid_mail?' do

    context 'validating headers' do
      it 'return true if X-Original-To header present' do
        # email to header check

      end

      # TODO: check Mail received header
      it 'return true if "Mail for" header present' do
        # email to header check

      end

      it 'returns false if mandatory header present' do

      end
    end

    context 'sender validation' do
      it 'returns false if sender ' do

      end

    end
  end

  describe '#processed_before?' do
    it 'returns false if already processed' do

    end

    it 'returns true if mail was not processed before' do

    end
  end

  describe '#sender_allowed?' do
    it 'validates that sender is allowed' do

    end

    it 'validates that sender is unallowed' do

    end
  end

end
