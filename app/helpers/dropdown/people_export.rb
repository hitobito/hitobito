module Dropdown
  class PeopleExport < Base

    attr_reader :user, :params

    def initialize(template, user, params, details, email_addresses)
      super(template, 'Export', :download)
      @user = user
      @params = params
      @details = details
      @email_addresses = email_addresses

      init_items
    end

    private

    def init_items
      csv_links
      label_links
      email_addresses_link
    end

    def csv_links
      csv_path = params.merge({format: :csv})

      if @details
        item('CSV', '#', ['Adressliste', csv_path], ['Alle Angaben', csv_path.merge(details: true)])
      else
        item('CSV', csv_path)
      end
    end

    def email_addresses_link
      if @email_addresses
        item('Email Addressen', params.merge({format: :email}), target: :new)
      end
    end

    def label_links
      if LabelFormat.all_as_hash.present?
        main_link = user.last_label_format_id ?
                    export_label_format_path(user.last_label_format_id) :
                    '#'
        item('Etiketten', main_link, *export_label_format_items)
      end
    end

    def export_label_format_items
      format_links = []
      if user.last_label_format_id?
        last_format = user.last_label_format
        format_links << [last_format.to_s, export_label_format_path(last_format.id), target: :new]
        format_links << nil
      end

      LabelFormat.all_as_hash.each do |id, label|
        format_links << [label, export_label_format_path(id), target: :new]
      end

      format_links
    end

    def export_label_format_path(id)
      params.merge(format: :pdf, label_format_id: id)
    end

  end
end
