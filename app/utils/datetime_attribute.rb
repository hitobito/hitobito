# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module DatetimeAttribute
  extend ActiveSupport::Concern

  included do
    class_attribute :datetime_attributes
    self.datetime_attributes = []

    before_validation :store_datetime_fields
  end

  private

  def store_datetime_fields
    datetime_attributes.each do |attr|
      # use accessors to obtain persisted values
      date = send("#{attr}_date")
      if date.present?
        hour = send("#{attr}_hour").presence || 0
        min = send("#{attr}_min").presence || 0
        begin
          date = ActiveRecord::ConnectionAdapters::Column.date_string_to_long_year(date)
          date = date.to_date
          send("#{attr}=", Time.zone.local(date.year, date.month, date.day, hour.to_i, min.to_i))
        rescue Exception
          errors.add(attr, 'ist nicht gültig')
        end
      else
        send("#{attr}=", nil)
      end
    end
  end

  def datetime_to(value, field)
    value ? send("datetime_to_#{field}", value) : nil
  end

  def datetime_to_date(value)
    value.to_date
  end

  def datetime_to_hour(value)
    value.hour
  end

  def datetime_to_min(value)
    value.min
  end

  def datetime_fields(attr)
    @datetimes ||= {}
    @datetimes[attr] ||= {}
  end

  module ClassMethods

    def datetime_attr(*attrs)
      attrs.each do |attr|
        datetime_attributes << attr

        attr_accessible attr, :"#{attr}_date", :"#{attr}_hour", :"#{attr}_min"

        # define field accessors
        [:date, :hour, :min].each do |field|
          accessor = :"#{attr}_#{field}"
          # getter
          define_method(accessor) do
            datetime_fields(attr)[field] ||= datetime_to(send(attr), field)
          end

          # setter
          define_method("#{accessor}=") do |value|
            send("#{attr}_will_change!") unless value == send(accessor)
            datetime_fields(attr)[field] = value
          end
        end
      end
    end

  end

end
