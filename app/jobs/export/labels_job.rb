# frozen_string_literal: true

#  Copyright (c) 2022, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::LabelsJob < Export::ExportBaseJob
  self.parameters = PARAMETERS + [:people_ids, :group_id]

  def initialize(format, user_id, people_ids, group_id, options)
    super(format, user_id, options)

    @people_ids = people_ids
    @group_id = group_id
  end

  def people
    @people ||= Person.where(id: @people_ids).order(order_statement)
  end

  def group
    @group ||= Group.find(@group_id)
  end

  # retain order of @people_ids but allow override in wagons
  def order_statement
    ArelArrayLiteral.new(@people_ids).array_position(Person.arel_table[:id])
  end

  def data
    case @format
    when :pdf
      if @options[:label_format_id]
        household = @options[:household] == "true"
        Export::Pdf::Labels.new(find_and_remember_label_format, label: @options[:address_type]).generate(people, household)
      else
        Export::Pdf::List.render(people, group)
      end
    end
  end

  def find_and_remember_label_format
    LabelFormat.find(@options[:label_format_id]).tap do |label_format|
      current_user = Person.find(@user_id)
      unless current_user.last_label_format_id == label_format.id
        current_user.update_column(:last_label_format_id, label_format.id)
      end
    end
  end
end
