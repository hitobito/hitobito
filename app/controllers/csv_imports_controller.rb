# encoding: utf-8

class CsvImportsController < ApplicationController
  attr_accessor :group
  attr_reader :importer, :parser, :role_type

  helper_method :group, :parser, :guess
  before_filter :load_group
  before_filter :custom_authorization
  decorates :group

  def define_mapping
    if model_params && valid_file?(model_params[:file])
      if parse_or_redirect(model_params[:file].read)
        flash.now[:notice] = parser.flash_notice
      end
    else
      flash[:alert] = 'Bitte wählen Sie eine gültige CSV Datei aus'
      redirect_to new_group_csv_imports_path(group)
    end
  end

  def create
    @role_type = model_params.delete(:role)

    if @role_type.blank? || !group.class.role_types.collect(&:sti_name).include?(@role_type)
      redirect_to new_group_csv_imports_path(group)
    elsif parse_or_redirect(params[:data])
      map_headers_and_import(model_params)

      set_flash(:notice, importer.success_count, "wurden erfolgreich importiert.")
      set_flash(:notice, importer.doublette_count, "wurden erfolgreich aktualisiert.")
      set_flash(:alert, importer.failure_count, "konnten nicht importiert werden.")
      flash[:alert] += importer.errors if importer.failure_count > 0

      redirect_to group_people_path(redirect_params)
    end
  end

  private

  def custom_authorization
    if action_name == "create" && model_params[:role]
      role = group.class.find_role_type!(model_params[:role]).new
      role.group_id = group.id
      authorize! :create, role
    else
      authorize! :new, group.roles.new
    end
  end

  def guess(header)
    @column_guesser ||= Import::PersonColumnGuesser.new(parser.headers)
    @column_guesser[header][:key]
  end

  def model_params
    params[:csv_import]
  end

  def load_group
    @group = Group.find(params[:group_id])
  end

  def valid_file?(io)
    io.present? && io.respond_to?(:content_type) && io.content_type =~ /text\//
  end

  def parse_or_redirect(data)
    @parser = Import::CsvParser.new(data.strip)

    unless parser.parse
      filename = model_params[:file] && model_params[:file].original_filename
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
    @importer.import
  end

  def set_flash(key, count, suffix)
    flash[key] ||= []
    flash[key] << "#{count} #{importer.human_name(count: count)} #{suffix}" if count > 0
  end

  def redirect_params
    name = case role_type
           when /Member/ then 'Mitglieder'
           when /External/ then 'Externe'
           else importer.human_role_name
           end
    {role_types: role_type, name: name}
  end

end
