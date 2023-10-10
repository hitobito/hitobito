#  Copyright (c) 2018-2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: events
#
#  id                          :integer          not null, primary key
#  applicant_count             :integer          default(0)
#  application_closing_at      :date
#  application_conditions      :text(16777215)
#  application_opening_at      :date
#  applications_cancelable     :boolean          default(FALSE), not null
#  cost                        :string(255)
#  description                 :text(16777215)
#  display_booking_info        :boolean          default(TRUE), not null
#  external_applications       :boolean          default(FALSE)
#  hidden_contact_attrs        :text(16777215)
#  location                    :text(16777215)
#  maximum_participants        :integer
#  motto                       :string(255)
#  name                        :string(255)      not null
#  number                      :string(255)
#  participant_count           :integer          default(0)
#  participations_visible      :boolean          default(FALSE), not null
#  priorization                :boolean          default(FALSE), not null
#  required_contact_attrs      :text(16777215)
#  requires_approval           :boolean          default(FALSE), not null
#  signature                   :boolean
#  signature_confirmation      :boolean
#  signature_confirmation_text :string(255)
#  state                       :string(60)
#  teamer_count                :integer          default(0)
#  type                        :string(255)
#  waiting_list                :boolean          default(TRUE), not null
#  created_at                  :datetime
#  updated_at                  :datetime
#  application_contact_id      :integer
#  contact_id                  :integer
#  creator_id                  :integer
#  kind_id                     :integer
#  updater_id                  :integer
#
# Indexes
#
#  index_events_on_kind_id  (kind_id)
#

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
