#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module CustomContentsHelper
  def format_custom_content_body(content)
    content.body&.to_plain_text&.truncate(100)
  end
end
