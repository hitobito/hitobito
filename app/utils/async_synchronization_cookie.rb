# encoding: utf-8

#  Copyright (c) 2012-2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AsyncSynchronizationCookie
  NAME = :async_synchronizations

  attr_accessor :cookies

  def initialize(cookies)
    @cookies = cookies
  end

  def set(mailing_list_id)
    values << to_value(mailing_list_id)
    cookies[NAME] = with_expiration(values)
  end

  def remove(mailing_list_id)
    values.delete(to_value(mailing_list_id))
    cookies[NAME] = with_expiration(values)
    cookies.delete(NAME) if values.empty?
  end

  private

  def values
    @values ||= cookies.key?(NAME) ? JSON.parse(cookies[NAME]) : []
  end

  def with_expiration(values)
    { value: values.uniq.to_json, expires: 1.day.from_now }
  end

  def to_value(mailing_list_id)
    { mailing_list_id: mailing_list_id }.stringify_keys
  end
end
