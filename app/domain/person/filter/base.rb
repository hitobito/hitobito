#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::Base
  # - has not to be encoded in URLs, ',' must be and thus generate a much longer string.
  ID_URL_SEPARATOR = "-".freeze

  class_attribute :required_ability, :permitted_args

  class << self
    def key
      name.demodulize.underscore
    end
  end

  attr_reader :attr, :args

  def initialize(attr, args)
    @attr = attr
    @args = args.slice(*permitted_args)
  end

  def apply(scope)
    scope
  end

  delegate :blank?, to: :args

  # Returns a serializable, persistable representation of this filter.
  def to_hash
    args
  end

  # Returns a representation of this filter suitable for request url params.
  def to_params
    args
  end

  # Returns customized roles join (e.g. for working with deleted roles)
  def roles_join
    nil
  end

  private

  def id_list(key)
    args[key] = args[key].to_s.split(ID_URL_SEPARATOR) unless args[key].is_a?(Array)
    args[key].collect!(&:to_i)
  end
end
