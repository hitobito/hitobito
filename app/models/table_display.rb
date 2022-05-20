#  Copyright (c) 2019-2022, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: table_displays
#
#  id                 :integer          not null, primary key
#  selected           :text(16777215)
#  table_model_class  :string(255)      not null
#  person_id          :integer          not null
#
# Indexes
#
#  index_table_displays_on_person_id_and_table_model_class  (person_id,table_model_class) UNIQUE
#

class TableDisplay < ActiveRecord::Base
  validates_by_schema

  belongs_to :person

  serialize :selected, Array
  before_save :allow_only_known_attributes!

  cattr_accessor :table_display_columns, :multi_columns

  def self.register_column(model_class, column_class, attrs = nil)
    if attrs.is_a? Array
      return attrs.each { |attr| register_column(model_class, column_class, attr) }
    end

    self.table_display_columns ||= {}
    self.table_display_columns[model_class.to_s] ||= {}
    self.table_display_columns[model_class.to_s][attrs.to_s] = column_class
  end

  def self.register_multi_column(model_class, multi_column_class)
    self.multi_columns ||= {}
    self.multi_columns[model_class.to_s] ||= []
    self.multi_columns[model_class.to_s] << multi_column_class
  end

  def self.for(person, table_model_class = nil)
    self.find_or_initialize_by(person: person, table_model_class: table_model_class.to_s)
        .allow_only_known_attributes!
  end

  def self.active_columns_for(person, model_class, list = nil)
    return [] unless Settings.table_displays

    self.for(person, model_class).active_columns(list)
  end

  def active_columns(list = nil)
    return [] unless Settings.table_displays

    if list.nil?
      selected
    else
      # Exclude columns which are selected but not available
      # This prevents showing the event questions of event A in the participants list of event B
      available = available(list)
      selected.select { |col| available.include? col }
    end
  end

  def column_for(attr, table: nil)
    column = relevant_columns.fetch(attr, nil) ||
        relevant_multi_columns.find { |col| col.can_display?(attr) }
    return if column.nil?

    instance = column.new(ability, model_class: table_model_class.constantize, table: table)
    block_given? ? (yield instance) : instance
  end

  def selected?(attr)
    selected.map(&:to_s).include?(attr.to_s)
  end

  def available(list = [])
    relevant_columns.keys + relevant_multi_columns.flat_map do |multi_column|
      multi_column.available(list)
    end
  end

  def sort_statements
    selected.map { |attr| [attr, column_for(attr).sort_by(attr)] }.to_h
  end

  def allow_only_known_attributes!
    selected.select! { |attr| known?(attr) }
    self
  end

  protected

  def ability
    @ability ||= Ability.new(person)
  end

  def known?(attr)
    relevant_columns.keys.include?(attr.to_s) || relevant_multi_columns.any? do |column_class|
      column_class.can_display? attr.to_s
    end
  end

  def relevant_columns
    table_display_columns.fetch(table_model_class, {})
  end

  def relevant_multi_columns
    multi_columns.fetch(table_model_class, [])
  end
end
