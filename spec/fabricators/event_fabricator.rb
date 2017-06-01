# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: events
#
#  id                          :integer          not null, primary key
#  type                        :string
#  name                        :string           not null
#  number                      :string
#  motto                       :string
#  cost                        :string
#  maximum_participants        :integer
#  contact_id                  :integer
#  description                 :text
#  location                    :text
#  application_opening_at      :date
#  application_closing_at      :date
#  application_conditions      :text
#  kind_id                     :integer
#  state                       :string(60)
#  priorization                :boolean          default(FALSE), not null
#  requires_approval           :boolean          default(FALSE), not null
#  created_at                  :datetime
#  updated_at                  :datetime
#  participant_count           :integer          default(0)
#  application_contact_id      :integer
#  external_applications       :boolean          default(FALSE)
#  applicant_count             :integer          default(0)
#  teamer_count                :integer          default(0)
#  signature                   :boolean
#  signature_confirmation      :boolean
#  signature_confirmation_text :string
#  creator_id                  :integer
#  updater_id                  :integer
#  applications_cancelable     :boolean          default(FALSE), not null
#

Fabricator(:event) do
  name { 'Eventus' }
  groups { [Group.all_types.first.first] }
  before_validation { |event| event.dates.build(start_at: Time.zone.local(2012, 05, 11)) }
end

Fabricator(:course, from: :event, class_name: :'Event::Course') do
  groups { [Group.all_types.detect { |t| t.event_types.include?(Event::Course) }.first] }
  kind { Event::Kind.where(short_name: 'SLK').first }
  number { 123 }
  priorization { true }
  requires_approval { true }
end
