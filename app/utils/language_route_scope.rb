# encoding: utf-8

#  Copyright (c) 2012-2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module LanguageRouteScope

  def language_scope(&block)
    languages = Settings.application.languages.to_hash.keys
    get "/:locale" => "dashboard#index", locale: /#{languages.join('|')}/

    if languages.size > 1
      scope "(:locale)", locale: /#{languages.join('|')}/, &block
    else
      yield
    end
  end

end
