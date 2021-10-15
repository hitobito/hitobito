# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::Messages
  class Letters < Export::Tabular::Base

    self.model_class = ::MessageRecipient
    self.row_class = LetterRow

    def attributes
      [:salutation, :address, :zip_code, :town, :country, :printed_address]
    end

  end
end
