# encoding: utf-8

#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


module Oauth
  class ApplicationsController < CrudController

    self.permitted_attrs = [:name, :redirect_uri, :confidential, scopes: []]

    def self.model_class
      Oauth::Application
    end

    def permitted_params
      super.tap do |attrs|
        attrs[:scopes] = Array(attrs.delete(:scopes)).join(' ')
      end
    end
  end
end
