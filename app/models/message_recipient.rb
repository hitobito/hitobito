# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class MessageRecipient < ActiveRecord::Base
  STATES = %w(delivered failed).freeze

  belongs_to :person
  belongs_to :message

  i18n_enum :state, STATES
end
