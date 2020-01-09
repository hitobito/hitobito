# encoding: utf-8

#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

ActsAsTaggableOn.remove_unused_tags = true
ActsAsTaggableOn.default_parser = TagCategoryParser
ActsAsTaggableOn::Tag.send(:include, CategorizedTags)

# https://github.com/rails/rails/commit/9def05385f1cfa41924bb93daa187615e88c95b9
ActsAsTaggableOn::Tag._validators[:name].each do |v|
  next unless v.is_a?(ActiveRecord::Validations::UniquenessValidator)
  v.instance_variable_set('@options', v.options.merge(case_sensitive: false).freeze)
end

