class CsvImportsController < ApplicationController
  attr_accessor :parent
  attr_reader :importer, :parser, :role_type

  helper_method :parent
  before_filter :load_group
  before_filter :custom_authorization

  def define_mapping
    data = model_params[:file].read # UploadedFile
    return unless parse_or_redirect(data)

    flash[:data] = parser.to_csv
    flash[:columns] = parser.headers
    flash[:notice] = parser.flash_notice
  end


  def create
    data = params[:data].split.join("\n")
    @role_type = model_params.delete(:role)

    return unless parse_or_redirect(data)

    map_headers_and_import

    set_flash(:notice, importer.success_count, "wurden erfolgreich importiert.")
    set_flash(:notice, importer.doublette_count, "wurden erfolgreich aktualisiert.")
    set_flash(:alert, importer.failure_count, "konnten nicht importiert werden.")
    flash[:alert] += importer.errors if importer.failure_count > 0

    redirect_to group_people_path(redirect_params)
  end

  private
  def custom_authorization
    if action_name == "create"
      role = model_params[:role].constantize.new
      role.group_id = parent.id
      authorize! :create, role
    else
      authorize! :new, parent.roles.new 
    end
  end

  def model_params
    params[:csv_import]
  end

  def load_group
    @parent = Group.find(params[:group_id])
    @group = GroupDecorator.decorate(parent)
  end

  def parse_or_redirect(data)
    @parser = Import::CsvParser.new(data)
    
    unless parser.parse
      filename = model_params[:file] && model_params[:file].original_filename
      filename ||= "csv formular daten" 
      flash[:alert] = parser.flash_alert(filename)
      redirect_to new_group_csv_imports_path(parent) 
      false
    else
      true
    end
  end

  def map_headers_and_import
    @importer = Import::PersonImporter.new(group: parent, 
                                           data: parser.map_headers(model_params), 
                                           role_type: role_type)
    @importer.import
  end

  def set_flash(key, count, suffix)
    flash[key] ||= []
    flash[key] += ["#{count} #{importer.human_name(count: count)} #{suffix}"] if count > 0
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
