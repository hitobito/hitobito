# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::Base

  # - has not to be encoded in URLs, ',' must be and thus generate a much longer string.
  ID_URL_SEPARATOR = '-'.freeze

  class_attribute :required_ability

  class << self
    def key
      name.demodulize.underscore
    end
  end

  attr_reader :attr, :args

  def initialize(attr, args)
    @attr = attr
    @args = args
  end

  def apply(scope)
    scope
  end

  def blank?
    args.blank?
  end

  def to_hash
    args
  end

  private

  def id_list(key)
    args[key] = args[key].to_s.split(ID_URL_SEPARATOR) unless args[key].is_a?(Array)
    args[key].collect!(&:to_i)
  end

end
