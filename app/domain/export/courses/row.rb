# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export
  module Courses
    class Row
      attr_reader :course, :hash, :max_dates, :contactable_keys

      delegate :number, :group_names, :description, :location, :contact, :application_closing_at,
        :participations_for, to: :course


      def initialize(course, list)
        @course = course
        @max_dates = list.max_dates
        @contactable_keys = list.contactable_keys

        @hash = populate
      end

      private

      def populate
        attributes
          .merge(dates)
          .merge(contactable_attributes(:contact, contact))
          .merge(contactable_attributes(:leader, leader && leader.person))
      end


      def attributes
        { group_names: group_names,
          number: number,
          kind: course.kind.label,
          description: description,
          state: state,
          location: location }.merge(additional_attributes)
      end

      def state
        I18n.t("activerecord.attributes.event/course.states.#{course.state}") if course.state
      end

      # Vorweekend, Kurs .. (ort wird noch in eine seperate spalte kommen)
      # am besten wahrscheinlich zusammenfassen und nicht als eigene spalten (label / duration)
      def dates
        dates_with_nulls.to_enum.with_index.each_with_object({}) do |(date, index), dates|
          dates[:"date_#{index}_label"] = date.label
          dates[:"date_#{index}_location"] = date.location
          dates[:"date_#{index}_duration"] = date.duration.to_s
        end
      end

      def dates_with_nulls
        Array.new(max_dates, OpenStruct.new(label: nil, duration: nil))
          .unshift(course.dates).flatten
      end

      # only the first leader is taken into account
      def leader
        @participation ||= participations_for(Event::Role::Leader).first
      end

      def contactable_attributes(prefix, contactable)
        attributes = contactable_keys.each_with_object({}) { |key, hash| hash[key] = nil }
        if contactable
          attributes[:name] = contactable.to_s
          attributes[:email] = contactable.email
          attributes[:address] = contactable.address
          attributes[:zip_code] = contactable.zip_code
          attributes[:town] = contactable.town
          attributes[:phone_numbers] = contactable.phone_numbers.map(&:to_s).join(', ')
          attributes.merge!(additional_contactable_attributes(contactable))
        end
        Hash[attributes.map {|k, v| [:"#{prefix}_#{k}", v] }]
      end

      def additional_attributes
        {}
      end

      def additional_contactable_attributes(contactable)
        {}
      end
    end
  end
end
