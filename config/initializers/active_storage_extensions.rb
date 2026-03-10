#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

ActiveSupport.on_load(:active_storage_blob) do
  scope :temporary, -> { where(temporary: true) }

  def self.create_temporary!(io:, filename:, content_type: nil, metadata: nil, service_name: nil)
    create_and_upload!(
      io: io,
      filename: filename,
      content_type: content_type,
      metadata: metadata,
      service_name: service_name
    ).tap do |blob|
      blob.update!(temporary: true)
    end
  end
end
