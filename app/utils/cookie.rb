#  Copyright (c) 2012-2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Cookie
  attr_accessor :cookies, :name, :attributes

  def initialize(cookies, name, attributes)
    @cookies = cookies
    @name = name
    @attributes = attributes
  end

  def set(options)
    values << to_value(options)
    cookies[name] = with_expiration(values)
  end

  def remove(options)
    values.delete(to_value(options))
    cookies[name] = with_expiration(values)
    cookies.delete(name) if values.empty?
  end

  private

  def values
    @values ||= cookies.key?(name) ? JSON.parse(cookies[name]) : []
  end

  def with_expiration(values)
    {value: values.to_json, expires: 1.day.from_now}
  end

  def to_value(options)
    options.slice(*attributes).stringify_keys
  end
end
