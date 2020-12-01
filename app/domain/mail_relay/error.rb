# frozen_string_literal: true

#  Copyright (c) 2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MailRelay
  class Error < StandardError
    attr_reader :original
    attr_reader :mail

    def initialize(message, mail, original = nil)
      super(message)
      @mail = mail
      @original = original
    end
  end
end
