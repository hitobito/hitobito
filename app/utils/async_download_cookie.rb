# encoding: utf-8

#  Copyright (c) 2012-2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AsyncDownloadCookie

  NAME = :async_downloads

  attr_accessor :cookies

  def initialize(cookies)
    @cookies = cookies
  end

  def set(name, type)
    values << to_value(name, type)
    cookies[NAME] = with_expiration(values)
  end

  def remove(name, type)
    values.delete(to_value(name, type))
    cookies[NAME] = with_expiration(values)
    cookies.delete(NAME) if values.empty?
  end

  private

  def values
    @values ||= cookies.key?(NAME) ? JSON.parse(cookies[NAME]) : []
  end

  def with_expiration(values)
    { value: values.to_json, expires: 1.day.from_now }
  end

  def to_value(name, type)
    { name: name, type: type }.stringify_keys
  end
end
