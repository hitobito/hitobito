#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
class SocialAccount < ActiveRecord::Base
  include ContactAccount

  self.ignored_columns += [FullTextSearchable::SEARCH_COLUMN]

  self.value_attr = :name

  validates_by_schema

  class << self
    def predefined_labels
      Settings.social_account.predefined_labels
    end
  end
end
