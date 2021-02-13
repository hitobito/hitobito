# frozen_string_literal: true
# == Schema Information
#
# Table name: help_texts
#
#  id         :integer          not null, primary key
#  controller :string(100)      not null
#  kind       :string(100)      not null
#  model      :string(100)
#  name       :string(100)      not null
#
# Indexes
#
#  index_help_texts_fields  (controller,model,kind,name) UNIQUE
#

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class HelpText < ActiveRecord::Base
  COLUMN_BLACKLIST = %w(id created_at updated_at deleted_at).freeze

  validates :name, uniqueness: { scope: [:controller, :model, :kind], case_sensitive: false }
  validates :body, presence: true, no_attachments: true
  before_validation :assign_combined_fields, if: :new_record?

  validates_by_schema

  include Globalized
  translates_rich_text :body

  validates_by_schema

  attr_accessor :context, :key


  def self.list
    order(Arel.sql(HelpTexts::List.new.order_statement)).order(:kind)
  end

  def to_s
    [entry.to_s, entry.translate(kind, name)].join(" - ") if persisted?
  end

  def entry
    @entry ||= HelpTexts::Entry.new(controller, model.classify.constantize)
  end

  def assign_combined_fields
    assign_and_validate(:context, "--", :controller, :model)
    assign_and_validate(:key, ".", :kind, :name)
  end

  private

  def assign_and_validate(attr, separator, *fields)
    values = send(attr).to_s.split(separator)
    values.zip(fields).each do |value, field|
      send("#{field}=", value)
    end
    errors.add(attr, :invalid) if fields.any? { |field| send(field).blank? }
  end

end
