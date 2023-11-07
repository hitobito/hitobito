# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Groups::SelfRegistrations
  class PersonComponent < ApplicationComponent

    attr_accessor :form

    def initialize(form:, policy_finder:)
      @form = form
      @policy_finder = policy_finder
      super()
    end

    def entry
      form.object
    end

    def self.title
      I18n.t("sac_cas.groups.self_registration.form.person_title")
    end
  end
end
