#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::CsvImportsController < ApplicationController

  attr_accessor :group
  attr_reader :importer, :parser, :entries, :can_manage_tags

  helper_method :group, :parser, :guess, :model_class, :entries, :role_name, :field_mappings

  before_action :load_group
  before_action :custom_authorization
  before_action :load_can_manage_tags

  decorates :group

  def new; end

  def define_mapping
    @role_type = params[:role_type] || group.default_role
    if valid_file_or_data?
      if parse_or_redirect
        flash.now[:notice] = parser.flash_notice
      end
    else
      flash[:alert] = translate(:invalid_file)
      redirect_to new_group_csv_imports_path(group)
    end
  end

  def preview
    valid_for_import? do
      @entries = importer.people.map(&:person)
      set_importer_flash_info
      set_importer_flash_errors
    end
  end

  def create
    valid_for_import? do
      if params[:button] != 'back'
        perform_import
      else
        define_mapping
        render :define_mapping
      end
    end
  end

  private

  def perform_import
    importer.people # populate
    importer.errors.clear # do not display previous validation errors
    importer.import
    set_importer_flash_info
    set_importer_flash_errors
    redirect_to group_people_path(redirect_params)
  end

  def set_importer_flash_info
    add_importer_info_to_flash(:notice, :new, importer.new_count)
    add_importer_info_to_flash(:notice, :updated, importer.update_count)
    add_importer_info_to_flash(:alert, :requests, importer.request_people.size)
    add_importer_info_to_flash(:alert, :failed, importer.failure_count)
  end

  def set_importer_flash_errors
    errors = importer.errors
    if errors.size > 10
      errors = errors.take(10) + ['...']
    end
    errors.each { |error| add_to_flash(:alert, error) }
  end

  def add_importer_info_to_flash(flash, key, count)
    if count > 0
      add_to_flash(flash,
                   translate([action_name, key].join('.').to_sym,
                             count: count,
                             role: importer.human_name(count: count)))
    end
  end

  def add_to_flash(key, text)
    flash_hash = action_name == 'preview' ? flash.now : flash
    flash_hash[key] ||= []
    flash_hash[key] << text if text.present?
  end

  def valid_for_import?
    if parse_or_redirect && sane_mapping? && valid_role?
      map_headers_and_import
      yield
    end
  end

  def valid_role?
    return true if params[:role_type].present?

    flash.now[:alert] = "#{Role.model_name} #{I18n.t('errors.messages.blank')}."
    render :define_mapping
    false
  end

  def custom_authorization
    if action_name == 'create'
      role = role_type.new
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

  def load_can_manage_tags
    @can_manage_tags = current_ability.can?(:manage_person_tags, group)
  end

  def valid_file?(io)
    io.present? &&
    io.respond_to?(:content_type) &&
    # windows sends csv files as application/vnd.excel, windows 10 as application/octet-stream
    io.content_type =~ /text\/|excel|octet-stream/
  end

  def parse_or_redirect
    @parser = Import::CsvParser.new(read_file_or_data)

    success = parser.parse
    unless success
      filename = file_param && file_param.original_filename
      filename ||= 'csv formular daten'
      flash[:alert] = parser.flash_alert(filename)
      redirect_to new_group_csv_imports_path(group)
    end
    success
  end

  def sane_mapping?
    duplicates = find_duplicate_mappings

    if duplicates.present?
      fields = Import::Person.fields.each_with_object({}) { |f, o| o[f[:key]] = f[:value] }
      list = duplicates.collect { |d| fields[d.to_s] }.join(', ')
      flash.now[:alert] = translate(:duplicate_keys, count: duplicates.size, list: list)
      render :define_mapping, status: :unprocessable_entity
      false
    else
      true
    end
  end

  def find_duplicate_mappings
    attrs = field_mappings.values
    attrs.select do |attr|
      attr.present? && attrs.count(attr) > 1
    end.uniq
  end

  def map_headers_and_import
    data = parser.map_data(field_mappings)
    @importer = Import::PersonImporter.new(data, group, role_type, override: override_behaviour,
                                                                   can_manage_tags: can_manage_tags)
    @importer.user_ability = current_ability
  end

  def redirect_params
    { filters: { role: { role_type_ids: [role_type.id] } }, name: importer.human_role_name }
  end

  def role_type
    @role_type ||= group.class.find_role_type!(params[:role_type])
  end

  def override_behaviour
    params[:update_behaviour] == 'override'
  end

  def file_param
    params[:csv_import] && params[:csv_import][:file]
  end

  def field_mappings
    params[:field_mappings] || {}
  end

  def role_name
    role_type.model_name.human
  end

  def model_class
    Person
  end

  def valid_file_or_data?
    valid_file?(file_param) || params[:data].present?
  end

  def read_file_or_data
    (file_param && read_file) || params[:data]
  end

  def read_file
    File.read(file_param.tempfile.path)
  end

end
