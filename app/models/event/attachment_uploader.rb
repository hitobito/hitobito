#  Copyright (c) 2015, Pro Natura Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::AttachmentUploader < Uploader::Base
  self.allowed_extensions = Settings.event.attachments.file_extensions.split(/\s+/)
end
