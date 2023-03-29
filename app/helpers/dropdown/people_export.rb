# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class PeopleExport < Base

    attr_reader :user, :params

    def initialize(template, user, params, options = {})
      super(template, translate(:button), :download)
      details, email_addresses, labels = true
      @user = user
      @params = params
      @details = options[:details]
      @email_addresses = options[:emails]
      @labels = options[:labels]
      @households = options[:households]
      @mailchimp_synchronization_path = options[:mailchimp_synchronization_path]

      init_items
    end

    private

    def init_items
      tabular_links(:csv)
      tabular_links(:xlsx)
      vcard_link
      pdf_link
      mailchimp_link
      label_links
      email_addresses_link
      email_addresses_link_outlook
    end

    def tabular_links(format) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      path = params.merge(format: format)
      item = add_item(translate(format), '#')
      if Settings.table_displays
        item.sub_items << Item.new(translate(:selection),
                                   path.merge(selection: true),
                                   data: { checkable: true })
      end
      item.sub_items << Item.new(translate(:addresses), path, data: { checkable: true })
      item.sub_items << Item.new(translate(:households),
                                 path.merge(household: true),
                                 data: { checkable: true }) if @households

      item.sub_items << Item.new(translate(:everything),
                                 path.merge(details: true),
                                 data: { checkable: true }) if @details
    end

    def vcard_link
      add_item(translate(:vcard), params.merge(format: :vcf), target: :new)
    end

    def mailchimp_link
      if @mailchimp_synchronization_path
        add_item('MailChimp', @mailchimp_synchronization_path, method: :post, remote: true)
      end
    end

    def email_addresses_link
      if @email_addresses
        add_item(translate(:emails), params.merge(format: :email), target: :new)
      end
    end

    def email_addresses_link_outlook
      if @email_addresses
        add_item(translate(:emails_outlook), params.merge(format: :email_outlook), target: :new)
      end
    end

    def pdf_link
      add_item(translate(:pdf), params.merge(format: :pdf))
    end

    def label_links
      if @labels && LabelFormat.exists?
        Dropdown::LabelItems.new(self, households: @households).add
      end
    end
  end

end
