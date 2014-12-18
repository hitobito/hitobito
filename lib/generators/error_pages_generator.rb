# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# always call with RAILS_GROUPS=assets
class ErrorPagesGenerator < Rails::Generators::Base

  ERROR_PAGES = [404, 500, 503]

  desc 'Generate a static error page based on the layout.'

  def generate_page
    ERROR_PAGES.each do |error|
      run "rm -f public/#{error}.html"
      request = Rack::MockRequest.env_for "/#{error}"
      request['action_dispatch.exception'] = StandardError.new 'generator'
      _, _, body = *Hitobito::Application.call(request)
      create_file "public/#{error}.html", body.join, force: true
    end
  end

end
