#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
class Person::AddRequest::Group < Person::AddRequest
  belongs_to :body, class_name: "::Group"

  validates :role_type, presence: true
  validate :assert_type_is_allowed_for_group

  alias_method :group, :body

  private

  def assert_type_is_allowed_for_group
    if role_type && group && !group.role_types.collect(&:sti_name).include?(role_type)
      errors.add(:role_type, :type_not_allowed)
    end
  end
end
