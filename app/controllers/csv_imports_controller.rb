# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CsvImportsController < ApplicationController
  attr_accessor :group
  attr_reader :importer, :parser, :entries

  helper_method :group, :parser, :guess, :model_class, :entries, :role_name,
                :relevant_attrs, :relevant_contacts, :contact_value, :field_mappings

  before_filter :load_group
  before_filter :custom_authorization
  decorates :group

  def define_mapping
    if valid_file_or_data?
      if parse_or_redirect
        flash.now[:notice] = parser.flash_notice
      end
    else
      flash[:alert] = 'Bitte wählen Sie eine gültige CSV Datei aus'
      redirect_to new_group_csv_imports_path(group)
    end
  end

  def preview
    valid_for_import? do
      @entries = importer.people.map(&:person)
      set_importer_flash_info('neu importiert.', 'aktualisiert.', 'nicht importiert.')
    end
  end

  def create
    valid_for_import? do
      if params[:button] == 'back'
        define_mapping
        render :define_mapping
      else
        importer.import
        @entries = importer.people.map(&:person)

        set_importer_flash_info('erfolgreich importiert.', 'erfolgreich aktualisiert.' , 'nicht importiert.')
        redirect_to group_people_path(redirect_params)
      end
    end
  end

  private

 def set_importer_flash_info(*suffixes)
   reversed = suffixes.reverse

   add_to_flash(:notice, pluralized(importer.new_count, reversed.pop))
   add_to_flash(:notice, pluralized(importer.doublette_count, reversed.pop))
   add_to_flash(:alert, pluralized(importer.failure_count, reversed.pop))
   importer.errors.each { |error| add_to_flash(:alert, error) }
 end

  def add_to_flash(key, text)
    flash_hash = action_name == 'preview' ? flash.now : flash
    flash_hash[key] ||= []
    flash_hash[key] << text if text.present?
  end

  def valid_for_import?
    if role_type.blank? || !group.class.role_types.collect(&:sti_name).include?(role_type)
      redirect_to new_group_csv_imports_path(group)
    elsif parse_or_redirect && sane_mapping?
      map_headers_and_import
      yield
    end
  end

  def custom_authorization
    if action_name == 'create' && role_type
      role = group.class.find_role_type!(role_type).new
      role.group_id = group.id
      authorize! :create, role
    else
      authorize! :new, group.roles.new
    end
  end

  def guess(header)
    @column_guesser ||= Import::PersonColumnGuesser.new(parser.headers, field_mappings)
    @column_guesser[header][:key]
  end

  def load_group
    @group = Group.find(params[:group_id])
  end

  def valid_file?(io)
    io.present? &&
    io.respond_to?(:content_type) &&
    io.content_type =~ /text\/|excel/ # windows sends csv files as application/vnd.excel
  end

  def parse_or_redirect
    @parser = Import::CsvParser.new(read_file_or_data.strip)

    unless parser.parse
      filename = file_param && file_param.original_filename
      filename ||= 'csv formular daten'
      flash[:alert] = parser.flash_alert(filename)
      redirect_to new_group_csv_imports_path(group)
      false
    else
      true
    end
  end

  def sane_mapping?
    duplicates = find_duplicate_mappings
    if duplicates.present?
      fields = Import::Person.fields.each_with_object({}) { |f, o| o[f[:key]] = f[:value] }
      list = duplicates.collect { |d| fields[d.to_s] }.join(', ')
      if duplicates.size == 1
        flash.now[:alert] = "#{list} wurde mehrfach zugewiesen"
      else
        flash.now[:alert] = "#{list} wurden mehrfach zugewiesen"
      end
      render :define_mapping
      false
    else
      true
    end
  end

  def find_duplicate_mappings
    duplicates = []
    seen = []
    field_mappings.each do |header, attr|
      if attr.present?
        if seen.include?(attr)
          duplicates << attr
        else
          seen << attr
        end
      end
    end
    duplicates.uniq
  end

  def map_headers_and_import
    data = parser.map_data(field_mappings)
    @importer = Import::PersonImporter.new(group: group,
                                           data: data,
                                           role_type: role_type)
  end

  def pluralized(count, suffix)
    words = wording[action_name.to_sym][count > 1 ? 0 : 1]
    [count, importer.human_name(count: count), words, suffix].join(' ') if count > 0
  end

  def wording
    @wording ||= { preview: %w(werden wird), create: %w(wurden wurde) }
  end

  def redirect_params
    # TODO: no role_types param anymore for groups_people, do not hard code External
    name = case role_type
           when /Member/ then 'Mitglieder'
           when /External/ then 'Externe'
           else importer.human_role_name
           end
    { role_types: role_type, name: name }
  end

  def role_type
    params[:role_type]
  end

  def file_param
    params[:csv_import] && params[:csv_import][:file]
  end

  def field_mappings
    params[:field_mappings] || {}
  end

  def role_name
    role_type.constantize.model_name.human
  end

  def model_class
    Person
  end

  def valid_file_or_data?
    valid_file?(file_param) || params[:data].present?
  end

  def read_file_or_data
    (file_param && file_param.read) || params[:data]
  end

  def relevant_attrs
    Import::Person.person_attributes.
      select { |f| field_mappings.values.include?(f[:key].to_s) }.
      map { |f| f[:key]  }
  end

  def relevant_contacts(key)
    @account_types ||= { phone_numbers: Import::AccountFields.new(PhoneNumber),
                         social_accounts: Import::AccountFields.new(SocialAccount) }
    @account_types[key].fields.
      select { |f| field_mappings.values.include?(f[:key].to_s) }.
      each { |contact| yield(contact) }
  end

  def contact_value(key, contacts)
    key = key.split('_').last
    contact = contacts.find { |c| c.label.downcase == key }
    contact && contact.value
  end

end
