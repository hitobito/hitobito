# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class Messages::LettersController < MessagesController

  self.permitted_attrs = [:subject, :content]

  def self.model_class
    @model_class ||= Messages::Letter
  end

  def full_entry_label
    "#{I18n.t('activerecord.models.messages/letter.one')} <i>#{ERB::Util.h(entry.to_s)}</i>"
        .html_safe
  end

end
