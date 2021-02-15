# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PersonDuplicateSeeder

  attr_accessor :encrypted_password

  def initialize
    @encrypted_password = BCrypt::Password.create("hito42bito", cost: 1)
  end

  def seed_duplicates
    candidates.each do |p|
      group = Group.order('RAND()').first
      role_type = group.role_types.reject(&:restricted?).sample
      return unless role_type.present?

      doublet_attrs = { first_name: p.first_name,
                        last_name: p.last_name,
                        company_name: p.company_name,
                        email: "#{Faker::Internet.user_name("#{p.first_name} #{p.last_name}")}@duplicates.example.com",
                        gender: %w(m w).shuffle.first,
                        encrypted_password: encrypted_password,
                        zip_code: p.zip_code,
                        birthday: p.birthday }
      doublet = Person.seed(:email, doublet_attrs).first

      Role.seed_once(:person_id, :group_id, :type, { person_id: doublet.id,
                                                   group_id:  group.id,
                                                   type:      role_type.sti_name })

      d = PersonDuplicate.new(person_1: p, person_2: doublet)
      d.assign_persons_sorted_by_id
      d.save
    end
  end

  private
  
  def candidates
    Person.order('RAND()').limit(10)
  end
end
