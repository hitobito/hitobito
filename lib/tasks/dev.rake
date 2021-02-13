# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

namespace :dev do
  namespace :oauth do

    desc "Obtain oauth access token"
    task :token, [:application_id, :redirect_uri, :code] => [:environment] do |_, args|
      app = Oauth::Application.find(args.fetch(:application_id))
      sh <<-BASH.strip_heredoc
        curl -v -H 'Accept: application/json' -X POST -d 'grant_type=authorization_code'  \
        -d 'client_id=#{app.uid}' -d 'client_secret=#{app.secret}' \
        -d 'redirect_uri=#{args.fetch(:redirect_uri)}' -d 'code=#{args.fetch(:code)}' \
        http://localhost:3000/oauth/token
      BASH
    end

    desc "Introspect oauth token"
    task :introspect, [:access_token, :token] do |_, args|
      access_token = args.fetch(:access_token)
      token = args.fetch(:token, access_token)
      sh <<-BASH.strip_heredoc
        curl -v -H 'Accept: application/json' \
        -H 'Authorization: Bearer #{access_token}' \
        -d 'token=#{token}' \
        http://localhost:3000/oauth/introspect
      BASH
    end

    desc "Obtain profile information"
    task :profile, [:access_token, :scope] do |_, args|
      access_token = args.fetch(:access_token)
      sh <<-BASH.strip_heredoc
        curl -v -H 'Accept: application/json' \
        -H 'Authorization: Bearer #{access_token}' \
        -H 'X-Scope: #{args[:scope]}' \
        http://localhost:3000/oauth/profile
      BASH
    end
  end

  namespace :help_texts do
    desc "Create all helptexts"
    task create: [:environment] do
      HelpText.destroy_all

      HelpTexts::List.new.entries.each do |entry|
        entry.labeled_list("action").each do |key, value|
          p [entry.controller_name, entry.model_class.to_s.underscore, :action, key]
          HelpText.create!(controller: entry.controller_name,
                           model: entry.model_class.to_s.underscore,
                           kind: :action,
                           name: key.split(".").last,
                           body: [key, entry.to_s, value].join(" "))
        end
        entry.labeled_list("field").each do |key, value|
          p [entry.controller_name, entry.model_class.to_s.underscore, :field, key]
          HelpText.create!(controller: entry.controller_name,
                           model: entry.model_class.to_s.underscore,
                           kind: :field,
                           name: key.split(".").last,
                           body: [key, entry.to_s, value].join(" "))
        end
      end
    end
  end
end
