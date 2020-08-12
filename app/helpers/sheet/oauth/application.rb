#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  module Oauth
    class Application < Sheet::Admin

      tab 'global.tabs.info',
          :oauth_application_path,
          if: (lambda do |view, application|
            application.present? && view.can?(:show, application)
          end)

      tab 'oauth.tabs.grants',
          :oauth_application_access_grants_path,
          if: (lambda do |view, application|
            application.present? && view.can?(:show, application)
          end)

      tab 'oauth.tabs.tokens',
          :oauth_application_access_tokens_path,
          if: (lambda do |view, application|
            application.present? && view.can?(:show, application)
          end)

    end
  end
end
