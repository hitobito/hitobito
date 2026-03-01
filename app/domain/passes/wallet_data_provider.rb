#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Passes
  class WalletDataProvider
    attr_reader :pass

    def initialize(pass)
      @pass = pass
    end

    def member_number
      pass.person.id.to_s.rjust(8, "0")
    end

    def member_name
      pass.person.full_name
    end

    def extra_google_text_modules
      []
    end

    def extra_apple_fields
      {}
    end

    def extra_apple_images
      {}
    end
  end
end
