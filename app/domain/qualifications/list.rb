# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Qualifications
  class List

    def initialize(person)
      @person = person
    end

    def qualifications
      @qualification ||= prepare
    end

    private

    def prepare
      list = load_qualifications
      by_kind = list.group_by(&:qualification_kind_id)
      list.each do |item|
        item.first_of_kind = true if first?(item, by_kind)
      end
    end

    def load_qualifications
      @person.qualifications.order_by_date.includes(:qualification_kind)
    end

    def first?(quali, by_kind)
      by_kind[quali.qualification_kind_id].first == quali
    end
  end
end
