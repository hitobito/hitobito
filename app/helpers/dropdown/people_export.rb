# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class PeopleExport < Base

    attr_reader :user, :params

    def initialize(template, user, params, details, email_addresses, labels = true)
      super(template, translate(:button), :download)
      @user = user
      @params = params
      @details = details
      @email_addresses = email_addresses
      @labels = labels

      init_items
    end

    private

    def init_items
      tabular_links(:csv)
      tabular_links(:xlsx)
      vcard_link
      pdf_link
      label_links
      email_addresses_link
    end

    def tabular_links(format)
      path = params.merge(format: format)

      if @details
        item = add_item(translate(format), '#')
        item.sub_items << Item.new(translate(:addresses), path)
        item.sub_items << Item.new(translate(:households), path.merge(household: true))
        item.sub_items << Item.new(translate(:everything), path.merge(details: true))
      else
        add_item(translate(format), path)
      end
    end

    def vcard_link
      add_item(translate(:vcard), params.merge(format: :vcf), target: :new)
    end

    def email_addresses_link
      if @email_addresses
        add_item(translate(:emails), params.merge(format: :email), target: :new)
      end
    end

    def pdf_link
      add_item(translate(:pdf), params.merge(format: :pdf), target: :new)
    end

    def label_links
      if @labels && LabelFormat.exists?
        Dropdown::LabelItems.new(self, condense_labels: true).add
      end
    end

  end

end
