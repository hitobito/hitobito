# frozen_string_literal: true

#  Copyright (c) 2022-2024, Jungschar EMK. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Rails.application.config.after_initialize do
  if FeatureGate.enabled?(:person_language)
    Person::PUBLIC_ATTRS << :language
    Person.used_attributes << :language
  end
end
