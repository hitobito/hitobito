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
      ordered_qualifications.each do |item|
        next unless first?(item)

        item.first_of_kind = true
        item.open_training_days = calculate_open_training_days(item) if training_days?(item)
      end
    end

    def ordered_qualifications
      @ordered_qualifications ||= @person
        .qualifications
        .order_by_date
        .includes(qualification_kind: :translations)
    end

    def by_kind
      @by_kind ||= ordered_qualifications.group_by(&:qualification_kind_id)
    end

    def first?(quali)
      by_kind[quali.qualification_kind_id].first == quali
    end

    def training_days?(quali)
      quali.qualification_kind.required_training_days.present?
    end

    def calculate_open_training_days(item)
      item.open_training_days = calculator.open_training_days(item.qualification_kind)
    end

    def calculator
      @calculator ||= Event::Qualifier::Calculator.new(
        courses,
        today,
        qualification_dates: maximum_qualification_dates_per_kind
      )
    end

    def courses
      Event::TrainingDays::CoursesLoader.new(
        @person,
        :participant,
        ordered_qualifications.pluck(:qualification_kind_id).uniq,
        minimal_qualification_start_at_per_kind,
        today
      ).load
    end

    def minimal_qualification_start_at_per_kind
      maximum_qualification_dates_per_kind.values.compact.min
    end

    def maximum_qualification_dates_per_kind
      @maximum_qualification_dates_per_kind ||= @person
        .qualifications.group(:qualification_kind_id).maximum(:start_at)
    end

    def today
      @today ||= Time.zone.today
    end
  end
end
