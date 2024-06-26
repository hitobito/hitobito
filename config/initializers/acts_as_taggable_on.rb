#  Copyright (c) 2012-2024, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Rails.application.reloader.to_prepare do
  ActsAsTaggableOn.remove_unused_tags = false
  ActsAsTaggableOn.default_parser = TagCategoryParser
  ActsAsTaggableOn::Tag.include CategorizedTags
  ActsAsTaggableOn::Tag.include TooltipForTags
  ActsAsTaggableOn::Tag.include IntegrateSubscriptionTags

  # https://github.com/rails/rails/commit/9def05385f1cfa41924bb93daa187615e88c95b9
  ActsAsTaggableOn::Tag._validators[:name].each do |v|
    next unless v.is_a?(ActiveRecord::Validations::UniquenessValidator)
    v.instance_variable_set('@options', v.options.merge(case_sensitive: false).freeze)
  end
end
