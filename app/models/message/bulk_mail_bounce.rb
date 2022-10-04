# frozen_string_literal: true

#  Copyright (c) 2022, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Message::BulkMailBounce < Message

  belongs_to :bounce_parent, class_name: 'Message::BulkMail'

end
