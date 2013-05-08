# encoding: utf-8

class CsvImportsController < ApplicationController
  attr_accessor :group
  attr_reader :importer, :parser, :entries

  helper_method :group, :parser, :guess, :model_class, :entries, :relevant_attrs, :role_name
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
      ary(flash.now, :notice, pluralized(importer.new_count, "neu importiert."))
      ary(flash.now, :notice, pluralized(importer.doublette_count, "aktualisiert."))
      ary(flash.now, :alert, pluralized(importer.failure_count, "nicht importiert."))
      importer.errors.each { |error| ary(flash.now, :alert, error) }
    end
  end

  def ary(flash_hash, key, text)
    flash_hash[key] ||= []
    flash_hash[key] << text if text.present?
  end


  def create
    valid_for_import? do
      importer.import

      ary(flash, :notice, pluralized(importer.new_count, "erfolgreich importiert."))
      ary(flash, :notice, pluralized(importer.doublette_count, "erfolgreich aktualisiert."))
      ary(flash, :alert, pluralized(importer.failure_count, "nicht importiert."))
      importer.errors.each { |error| ary(flash.now, :alert, error) }

      redirect_to group_people_path(redirect_params)
    end
  end

  private

  def valid_for_import?
    if role_type.blank? || !group.class.role_types.collect(&:sti_name).include?(role_type)
      redirect_to new_group_csv_imports_path(group)
    elsif parse_or_redirect
      map_headers_and_import(params[:csv_import])
      yield
    end
  end

  def custom_authorization
    if action_name == "create" && role_type
      role = group.class.find_role_type!(role_type).new
      role.group_id = group.id
      authorize! :create, role
    else
      authorize! :new, group.roles.new
    end
  end

  def guess(header)
    @column_guesser ||= Import::PersonColumnGuesser.new(parser.headers, params[:csv_import])
    @column_guesser[header][:key]
  end

  def load_group
    @group = Group.find(params[:group_id])
  end

  def valid_file?(io)
    io.present? && io.respond_to?(:content_type) && io.content_type =~ /text\//
  end

  def parse_or_redirect
    @parser = Import::CsvParser.new(read_file_or_data.strip)

    unless parser.parse
      filename = file_param && file_param.original_filename
      filename ||= "csv formular daten"
      flash[:alert] = parser.flash_alert(filename)
      redirect_to new_group_csv_imports_path(group)
      false
    else
      true
    end
  end

  def map_headers_and_import(header_mapping)
    data = parser.map_data(header_mapping)
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
    name = case role_type
           when /Member/ then 'Mitglieder'
           when /External/ then 'Externe'
           else importer.human_role_name
           end
    {role_types: role_type, name: name}
  end

  def role_type
    params[:role_type]
  end

  def file_param
    params[:csv_import] && params[:csv_import][:file]
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
    Import::Person.person_attributes.map { |f| f[:key] }
  end

end
