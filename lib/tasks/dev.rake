# frozen_string_literal: true

#  Copyright (c) 2019-2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

namespace :dev do
  namespace :oauth do

    desc 'Obtain oauth access token'
    task :token, [:application_id, :redirect_uri, :code] => [:environment] do |_, args|
      app = Oauth::Application.find(args.fetch(:application_id))
      sh <<-BASH.strip_heredoc
        curl -v -H 'Accept: application/json' -X POST -d 'grant_type=authorization_code'  \
        -d 'client_id=#{app.uid}' -d 'client_secret=#{app.secret}' \
        -d 'redirect_uri=#{args.fetch(:redirect_uri)}' -d 'code=#{args.fetch(:code)}' \
        http://localhost:3000/oauth/token
      BASH
    end

    desc 'Introspect oauth token'
    task :introspect, [:access_token, :token] do |_, args| # rubocop:disable Rails/RakeEnvironment
      access_token = args.fetch(:access_token)
      token = args.fetch(:token, access_token)
      sh <<-BASH.strip_heredoc
        curl -v -H 'Accept: application/json' \
        -H 'Authorization: Bearer #{access_token}' \
        -d 'token=#{token}' \
        http://localhost:3000/oauth/introspect
      BASH
    end

    desc 'Obtain profile information'
    task :profile, [:access_token, :scope] do |_, args| # rubocop:disable Rails/RakeEnvironment
      access_token = args.fetch(:access_token)
      sh <<-BASH.strip_heredoc
        curl -v -H 'Accept: application/json' \
        -H 'Authorization: Bearer #{access_token}' \
        -H 'X-Scope: #{args[:scope]}' \
        http://localhost:3000/oauth/profile
      BASH
    end
  end

  namespace :local do
    desc 'Create a local user with admin-permissions'
    task :admin, [:username] => :environment do |_, args|
      username = args.fetch(:username, 'tester@example.net')
      password = 'hitobito is the best software to manage people in complex group hierachies'

      me = Person.find_by(email: username) ||
        Person.new(first_name: 'Tom', last_name: 'Tester',
                   email: username, birthday: '1970-01-01')

      me.password = me.password_confirmation = password
      me.save!(validate: false)

      me.confirmed_at = Time.zone.now
      me.confirmation_token = nil
      me.save!(validate: false)

      puts <<~MESSAGE

        Created or updated the user #{username} to now have the password
        #{password.inspect}

      MESSAGE

      root = Group.roots.first
      permissions = [:admin, :impersonation, :layer_and_below_full]
      existing_role_types = me.roles.pluck(:type).map(&:to_s)

      powerful_roles = Group.where(layer_group_id: root.layer_group_id).flat_map do |group|
        permissions.flat_map do |permission|
          group.class.roles.select { |r| r.permissions.include?(permission) }
        end.uniq.compact.product([group.id])
      end

      powerful_roles.each do |role_type, role_group_id|
        next if existing_role_types.include?(role_type.to_s)

        me.roles << Role.new(type: role_type, group_id: role_group_id)
      end

      me.reload # clear out invalid roles

      puts <<~MESSAGE
        The User now has hopefully useful roles:

          - #{me.roles.join("\n  - ")}

      MESSAGE
    end
  end

  namespace :help_texts do
    desc 'Create all helptexts'
    task create: [:environment] do
      HelpText.destroy_all

      HelpTexts::List.new.entries.each do |entry|
        entry.labeled_list('action').each do |key, value|
          p [entry.controller_name, entry.model_class.to_s.underscore, :action, key]
          HelpText.create!(controller: entry.controller_name,
                           model: entry.model_class.to_s.underscore,
                           kind: :action,
                           name: key.split('.').last,
                           body: [key, entry.to_s, value].join(' '))
        end
        entry.labeled_list('field').each do |key, value|
          p [entry.controller_name, entry.model_class.to_s.underscore, :field, key]
          HelpText.create!(controller: entry.controller_name,
                           model: entry.model_class.to_s.underscore,
                           kind: :field,
                           name: key.split('.').last,
                           body: [key, entry.to_s, value].join(' '))
        end
      end
    end
  end
end

task 'bin/version': ['app/domain/release_version.rb'] do |file|
  content = Pathname.new(file.name).read

  start_marker = '### RELEASE_VERSION_CODE START'
  end_marker = '### RELEASE_VERSION_CODE END'
  pattern = /(.*)#{start_marker}.*#{end_marker}(.*)/m

  matches = content.match(pattern)

  before = matches[1]
  lib = Pathname.new(file.prerequisites.first).read
  after = matches[2]

  Pathname.new(file.name).open('w') do |f|
    f << before
    f << "#{start_marker}\n"
    f << lib
    f << end_marker
    f << after
  end
end
file 'app/domain/release_version.rb'
