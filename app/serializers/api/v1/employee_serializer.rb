# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V1
    class EmployeeSerializer < ApiSerializer
      attributes  :shortname,
                  :firstname,
                  :lastname,
                  :email,
                  :marital_status,
                  :nationalities,
                  :graduation,
                  :city,
                  :birthday,
                  :ldapname

      attribute :is_employed do |employee|
        !employee.current_employment.nil?
      end

      attribute :employed_within_three_months do |employee|
        employee.employments.any? do |employment|
          employment.start_date.between?(Time.zone.today, 3.months.from_now)
        end
      end

      attribute :department_shortname do |employee|
        employee.department&.shortname
      end

      attribute :department_name do |employee|
        employee.department&.name
      end

      attribute :employment_roles do |employee|
        Array.wrap(employee.current_employment&.employment_roles_employments).map do |employment_roles_employment|
          {
            name: employment_roles_employment.employment_role.name,
            percent: employment_roles_employment.percent.to_f,
            role_level: employment_roles_employment.employment_role_level&.name
          }
        end
      end

      # attribute annotations for the generated api docs

      annotate_attributes :shortname, :firstname, :lastname,
                          :email, :graduation, :department_shortname,
                          :department_name, :city,
                          type: :string

      annotate_attribute :marital_status,
                         type: :string,
                         enum: Employee.marital_statuses.keys

      annotate_attribute :nationalities,
                         description: 'Two letter country codes as specified in ISO 3166',
                         type: :array,
                         items: {
                           type: :string
                         }

      annotate_attribute :employment_roles,
                         type: :object,
                         properties: {
                           name: {
                             type: :string,
                             description: 'The role name'
                           },
                           percent: {
                             type: :number,
                             format: :float
                           },
                           role_level: {
                             type: :string,
                             description: 'The level of the role'
                           }
                         }

      annotate_attribute :birthday,
                         type: :string,
                         format: :date,
                         description: 'The employee’s birth date in YYYY-MM-DD format'

      annotate_attribute :employed_within_three_months,
                         type: :boolean,
                         description: 'Whether the employee has a employment that starts in the next three months or not'
    end
  end
end
