#  Copyright (c) 2018-2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
class EventSerializer < EventListSerializer
  include Rails.application.routes.url_helpers

  schema do
    property :attachments, (item.attachments.includes(file_attachment: :blob).map do |attachment|
      {
        file_name: upload_display_helper.upload_name(attachment, :file),
        url: attachment_url(attachment)
      }
    end)
  end

  def attachment_url(attachment)
    file = upload_display_helper.upload_url(attachment, :file)
    rails_blob_url(file, host: context[:controller].request.host_with_port)
  end

  def upload_display_helper
    @upload_display_helper ||= Class.new do
      include UploadDisplayHelper
    end.new
  end

  private

  def default_url_options(options = {})
    options.merge(Rails.application.routes.default_url_options)
  end
end
