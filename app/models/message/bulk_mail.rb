# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class Message::BulkMail < Message
  delegate :mail_from, to: :mail_log

  def save_as_file
    binding.pry
    File.open('/rails/mailing_list/bulk_mail/' + self.id + '.yaml', 'wb') { |f| f.write(YAML.dump(self)) }
  end
end
