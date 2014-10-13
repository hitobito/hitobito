# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class PeopleExport < Base

    attr_reader :user, :params

    def initialize(template, user, params, details, email_addresses)
      super(template, translate(:button), :download)
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
      csv_path = params.merge(format: :csv)

      if @details
        csv_item = add_item(translate(:csv), '#')
        csv_item.sub_items << Item.new(translate(:addresses), csv_path)
        csv_item.sub_items << Item.new(translate(:everything), csv_path.merge(details: true))
      else
        add_item(translate(:csv), csv_path)
      end
    end

    def email_addresses_link
      if @email_addresses
        add_item(translate(:emails), params.merge(format: :email), target: :new)
      end
    end

    def label_links
      if LabelFormat.all_as_hash.present?
        label_item = add_item(translate(:labels), main_label_link)
        add_last_used_format_item(label_item)
        add_label_format_items(label_item)
      end
    end

    def main_label_link
      if user.last_label_format_id
        export_label_format_path(user.last_label_format_id)
      else
        '#'
      end
    end

    def add_last_used_format_item(parent)
      if user.last_label_format_id?
        last_format = user.last_label_format
        parent.sub_items << Item.new(last_format.to_s,
                                     export_label_format_path(last_format.id),
                                     target: :new)
        parent.sub_items << Divider.new
      end
    end

    def add_label_format_items(parent)
      LabelFormat.all_as_hash.each do |id, label|
        parent.sub_items << Item.new(label, export_label_format_path(id), target: :new)
      end
    end

    def export_label_format_path(id)
      params.merge(format: :pdf, label_format_id: id)
    end

  end
end
