# frozen_string_literal: true

#  Copyright (c) 2023-2024, Pfadibewegung Schweiz. This file is part of
#  hitobito_youth and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

class Event::ParticipationContactData::ManagedController <
  Event::ParticipationContactDatasController
  before_action :assert_feature_enabled

  def update
    if any_duplicates?
      entry.errors.add(:base, :duplicates_present) if any_duplicates?
      render :edit, status: :unprocessable_entity
    else
      super
    end
  end

  private

  def person
    @person ||= Person.new.tap do |person|
      person.people_managers.build(manager: current_user, managed: person)
    end
  end

  def contact_data_class
    Event::ParticipationContactDatas::Managed
  end

  def any_duplicates?
    relevant_person_attrs = entry.person.attributes
      .transform_keys(&:to_sym)
      .slice(*People::DuplicateConditions::ATTRIBUTES)

    person_duplicate_finder.find(relevant_person_attrs).present?
  end

  def person_duplicate_finder
    @person_duplicate_finder ||= Import::PersonDuplicateFinder.new
  end

  def privacy_policy_param
    params[:event_participation_contact_datas_managed][:privacy_policy_accepted]
  end

  def assert_feature_enabled
    FeatureGate.assert!("people.people_managers") &&
      FeatureGate.assert!("people.people_managers.self_service_managed_creation")
  end
end
