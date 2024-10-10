#  Copyright (c) 2018-2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: events
#
#  id                               :integer          not null, primary key
#  applicant_count                  :integer          default(0)
#  application_closing_at           :date
#  application_conditions           :text
#  application_opening_at           :date
#  applications_cancelable          :boolean          default(FALSE), not null
#  automatic_assignment             :boolean          default(FALSE), not null
#  cost                             :string
#  description                      :text
#  display_booking_info             :boolean          default(TRUE), not null
#  external_applications            :boolean          default(FALSE)
#  globally_visible                 :boolean
#  hidden_contact_attrs             :text
#  location                         :text
#  maximum_participants             :integer
#  minimum_participants             :integer
#  motto                            :string
#  name                             :string
#  notify_contact_on_participations :boolean          default(FALSE), not null
#  number                           :string
#  participant_count                :integer          default(0)
#  participations_visible           :boolean          default(FALSE), not null
#  priorization                     :boolean          default(FALSE), not null
#  required_contact_attrs           :text
#  requires_approval                :boolean          default(FALSE), not null
#  shared_access_token              :string
#  signature                        :boolean
#  signature_confirmation           :boolean
#  signature_confirmation_text      :string
#  state                            :string(60)
#  teamer_count                     :integer          default(0)
#  training_days                    :decimal(5, 2)
#  type                             :string
#  waiting_list                     :boolean          default(TRUE), not null
#  created_at                       :datetime
#  updated_at                       :datetime
#  application_contact_id           :integer
#  contact_id                       :integer
#  creator_id                       :integer
#  kind_id                          :integer
#  updater_id                       :integer
#
# Indexes
#
#  index_events_on_kind_id              (kind_id)
#  index_events_on_shared_access_token  (shared_access_token)
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
