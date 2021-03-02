# frozen_string_literal: true

#  Copyright (c) 2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailingList::UnsubscribeUrl
  class << self
    include ActionView::Helpers::UrlHelper

    delegate :url_helpers, to: 'Rails.application.routes'
    delegate :group_mailing_list_url, to: :url_helpers

    def unsubscribe_link(mailing_list, html: false)
      return '' unless mailing_list.subscribable?

      if html
        link_to('Abmelden / Unsubscribe', unsubscribe_url(mailing_list))
      else
        'Abmelden / Unsubscribe: ' + unsubscribe_url(mailing_list)
      end
    end

    private

    def unsubscribe_url(mailing_list)
      group_mailing_list_url(group_id: mailing_list.group_id, id: mailing_list.id, host: host, protocol: protocol)
    end

    def host
      ENV.fetch('RAILS_HOST_NAME', 'localhost:3000')
    end

    def protocol
      ssl = Rails.application.config.force_ssl
      ssl ? :https : :http
    end

  end

end

