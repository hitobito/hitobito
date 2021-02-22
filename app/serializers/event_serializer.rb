#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
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

class EventSerializer < ApplicationSerializer
  schema do
    json_api_properties

    map_properties :name,
      :description,
      :motto,
      :cost,
      :maximum_participants,
      :participant_count,
      :location,
      :application_opening_at,
      :application_closing_at,
      :application_conditions,
      :state,
      :teamer_count

    apply_extensions(:public)

    property :external_application_link, h.group_public_event_url(item.groups.first, item.id)

    entity :kind, item.kind, EventKindSerializer if item.object.class.method_defined?(:kind)

    entities :dates, item.dates, EventDateSerializer
    entities :group, item.groups.decorate, GroupSerializer
  end
end
