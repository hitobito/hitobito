# frozen_string_literal: true

#  Copyright (c) 2019-2024, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

namespace :dev do
  namespace :oauth do

    desc 'Obtain oauth access token'
    task :token, [:application_id, :redirect_uri, :code] => [:environment] do |_, args|
      app = Oauth::Application.find(args.fetch(:application_id))
      sh <<~BASH
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
      sh <<~BASH
        curl -v -H 'Accept: application/json' \
        -H 'Authorization: Bearer #{access_token}' \
        -d 'token=#{token}' \
        http://localhost:3000/oauth/introspect
      BASH
    end

    desc 'Obtain profile information'
    task :profile, [:access_token, :scope] do |_, args| # rubocop:disable Rails/RakeEnvironment
      access_token = args.fetch(:access_token)
      sh <<~BASH
        curl -v -H 'Accept: application/json' \
        -H 'Authorization: Bearer #{access_token}' \
        -H 'X-Scope: #{args[:scope]}' \
        http://localhost:3000/oauth/profile
      BASH
    end
  end

  namespace :local do
    desc 'Create a local user with admin-permissions'
    task admin: :environment do
      abort('This is for development purposes only.') unless Rails.env.development?
      abort('This needs at least one wagon to work') if Wagons.all.blank?
      abort('This needs a group-structure to work') if Group.subclasses.blank?

      username = 'tester@example.net'
      password = 'hitobito is the best software to manage people in complex group hierarchies'

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

      if me.roles.any?(&:two_factor_authentication_enforced)
        me.two_fa_secret = %w(
          2R7IGBJMSZV1L7TPLDI8HDO0UD8LCQ6NMVJWDYKW6I8XXM9RGU6G4II9KOJ2O8J6NUV
          BM4DUGAKQ0EL41TVR1BKN5YHA5IVATD58BWZTQ0T46X85ED2HQ9CYZCAQYK0JMXOSKN
          DZNEUSG5ZCS9ZURT7LB7HGK1AXD350LT9Q4PYO8ZX4ZDSCZF96N4LWFOH4C92DJ2NV
        ).join
        me.two_factor_authentication = 'totp'
        me.save!(validate: false)

        qr_code = Pathname.new('tmp/tom-tester-otp.png')
        qr_code.delete if qr_code.exist?

        otp = People::OneTimePassword.new(me.two_fa_secret, person: me)
        otp.provisioning_qr_code.save(qr_code.to_s)

        case ENV.fetch('TERM', nil)
        when 'xterm-kitty'
          puts 'This is the QR-Code for the TOTP/2FA-Setup'
          system("kitty +kitten icat #{qr_code}")
        else
          puts "The QR-Code for TOTP/2FA-Setup is located at #{qr_code}"
        end

        puts 'If you have setup 2FA for a dev-hitobito already, you may ignore this'
        puts 'as the generated codes should be the same.'
        puts
      end

      unless me.valid?
        puts 'This person has invalid data for this wagon. Nothing serious, just keep'
        puts 'in mind: You need to fill additional fields if you update it.'
        puts
      end

      puts 'Done.'
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
