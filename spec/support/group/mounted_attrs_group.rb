# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::MountedAttrsGroup < Group

  mounted_attr :string, :string
  mounted_attr :string_nullable, :string, null: true
  mounted_attr :string_non_nullable, :string, null: false

  mounted_attr :string_with_default, :string, default: 'default'
  mounted_attr :string_with_default_nullable, :string, default: 'default', null: true
  mounted_attr :string_with_default_non_nullable, :string, default: 'default', null: false

  mounted_attr :string_with_default_empty, :string, default: ''
  mounted_attr :string_with_default_emtpy_nullable, :string, default: '', null: true
  mounted_attr :string_with_default_empty_non_nullable, :string, default: '', null: false

  mounted_attr :string_with_default_null, :string, default: nil
  mounted_attr :string_with_default_null_nullable, :string, default: nil, null: true
  mounted_attr :string_with_default_null_non_nullable, :string, default: nil, null: false

  mounted_attr :integer, :integer
  mounted_attr :integer_nullable, :integer, null: true
  mounted_attr :integer_non_nullable, :integer, null: false

  mounted_attr :integer_with_default, :integer, default: 42
  mounted_attr :integer_with_default_nullable, :integer, default: 42, null: true
  mounted_attr :integer_with_default_non_nullable, :integer, default: 42, null: false

  mounted_attr :integer_with_default_zero, :integer, default: 0
  mounted_attr :integer_with_default_zero_nullable, :integer, default: 0, null: true
  mounted_attr :integer_with_default_zero_non_nullable, :integer, default: 0, null: false

  mounted_attr :integer_with_default_null, :integer, default: nil
  mounted_attr :integer_with_default_null_nullable, :integer, default: nil, null: true
  mounted_attr :integer_with_default_null_non_nullable, :integer, default: nil, null: false

  mounted_attr :boolean, :boolean
  mounted_attr :boolean_nullable, :boolean, null: true
  mounted_attr :boolean_non_nullable, :boolean, null: false

  mounted_attr :boolean_with_default_false, :boolean, default: false
  mounted_attr :boolean_with_default_false_nullable, :boolean, default: false, null: true
  mounted_attr :boolean_with_default_false_non_nullable, :boolean, default: false, null: false

  mounted_attr :boolean_with_default_true, :boolean, default: true
  mounted_attr :boolean_with_default_true_nullable, :boolean, default: true, null: true
  mounted_attr :boolean_with_default_true_non_nullable, :boolean, default: true, null: false

  mounted_attr :boolean_with_default_null, :boolean, default: nil
  mounted_attr :boolean_with_default_null_nullable, :boolean, default: nil, null: true
  mounted_attr :boolean_with_default_null_non_nullable, :boolean, default: nil, null: false

end
