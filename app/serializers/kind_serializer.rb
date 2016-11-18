# encoding: utf-8
# == Schema Information
#
# Table name: event_kinds
#
#   t.integer  "event_kind_id",          null: false
#   t.string   "locale",                 null: false
#   t.datetime "created_at",             null: false
#   t.datetime "updated_at",             null: false
#   t.string   "label",                  null: false
#   t.string   "short_name"
#   t.text     "general_information"
#   t.text     "application_conditions"
#
#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class KindSerializer < ApplicationSerializer

  schema do
    details = h.can?(:show_details, item)
    #json_api_properties
    type item.class.name
    property :id, item.id.to_s
    property :type, item.class.name
    property :href, h.event_kind_url(item, format: :json)
    map_properties :label, :short_name, :general_information

    if details
      map_properties :created_at, :updated_at
    end

  end
end
