# frozen_string_literal: true

#  Copyright (c) 2019-2024, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

namespace :dev do
  namespace :oauth do
    desc "Obtain oauth access token"
    task :token, [:application_id, :code, :redirect_uri] => [:environment] do |_, args|
      app = Oauth::Application.find(args.fetch(:application_id))
      redirect_uri = args.fetch(:redirect_uri, app.redirect_uri.split("\n").first)
      sh <<~BASH
          curl -s -H 'Accept: application/json' -X POST -d 'grant_type=authorization_code'  \
          -d 'client_id=#{app.uid}' -d 'client_secret=#{app.secret}' \
          -d "redirect_uri=#{redirect_uri}" -d 'code=#{args.fetch(:code)}' \
        http://localhost:3000/oauth/token | jq .
      BASH
    end

    desc "Obtain refresh token, wrap as follows to read into env: read access refresh id < <(echo $(rake .. | jq -r '.access_token, .refresh_token, .id_token'))"
    task :refresh, [:application_id, :refresh_token, :populate_env] => [:environment] do |_, args|
      app = Oauth::Application.find(args.fetch(:application_id))
      sh <<~BASH
          curl -s -H 'Accept: application/json' -X POST -d 'grant_type=authorization_code'  \
          -d 'client_id=#{app.uid}' -d 'client_secret=#{app.secret}' \
          -d 'scope=#{app.scopes}' \
          -d "grant_type=refresh_token" -d 'refresh_token=#{args.fetch(:refresh_token)}' \
        http://localhost:3000/oauth/token | jq .
      BASH
    end

    desc "Introspect oauth token"
    task :introspect, [:access_token, :token] do |_, args| # rubocop:disable Rails/RakeEnvironment
      access_token = args.fetch(:access_token)
      token = args.fetch(:token, access_token)
      sh <<~BASH
        curl -s -H 'Accept: application/json' \
        -H 'Authorization: Bearer #{access_token}' \
        -d 'token=#{token}' \
        http://localhost:3000/oauth/introspect | jq .
      BASH
    end

    desc "Destroy oauth session"
    task :destroy, [:id_token] do |_, args| # rubocop:disable Rails/RakeEnvironment
      id_token = args.fetch(:id_token)
      sh <<~BASH
        curl -s -H 'Accept: application/json' \
        http://localhost:3000/oidc/logout?id_token_hint=#{id_token}
      BASH
    end

    desc "Obtain profile information"
    task :profile, [:access_token, :scope] do |_, args| # rubocop:disable Rails/RakeEnvironment
      access_token = args.fetch(:access_token)
      sh <<~BASH
        curl -s -H 'Accept: application/json' \
        -H 'Authorization: Bearer #{access_token}' \
        -H 'X-Scope: #{args[:scope]}' \
        http://localhost:3000/oauth/profile | jq .
      BASH
    end

    desc "Obtain userinfo information"
    task :userinfo, [:access_token] do |_, args| # rubocop:disable Rails/RakeEnvironment
      access_token = args.fetch(:access_token)
      sh <<~BASH
        curl -s -H 'Accept: application/json' \
        -H 'Authorization: Bearer #{access_token}' \
        http://localhost:3000/oauth/userinfo | jq .
      BASH
    end

    desc "Show example OAuth-Authorization Screen. Call without arguments to use/create a test oauth app"
    task :authorization, [:application_id, :prompt, :redirect_uri] => [:environment] do |_, args|
      def find_or_create_app(application_id)
        return Oauth::Application.find(application_id) if application_id.present?

        Oauth::Application
          .create_with(scopes: "email", name: "localhost Test Application")
          .find_or_create_by!(redirect_uri: "http://localhost:3001/callback")
      end

      def start_callback_server
        require "webrick"
        server = WEBrick::HTTPServer.new(
          Port: 3001,
          Host: "localhost",
          Logger: WEBrick::Log.new(nil, WEBrick::Log::FATAL),
          AccessLog: []
        )
        server.mount_proc "/callback" do |req, res|
          puts "Received request: #{req.request_method} #{req.path}"

          puts "URL parameters:"
          req.query.each do |key, value|
            puts "  #{key}: #{value}"
          end

          puts "Headers:"
          req.header do |key, value|
            puts "  #{key}: #{value.inspect}"
          end

          puts "Request Body/Payload:"
          if req.body && !req.body.empty?
            puts "  #{req.body}"
          else
            puts "  No body content"
          end

          res.status = 200
          res["Content-Type"] = "text/plain"
          res.body = "Request received. Check the console for details."

          server.shutdown
        end

        trap "INT" do
          server.shutdown
        end

        Thread.new do
          puts "🚀 Starting server at http://localhost:3001/"
          puts "   Waiting for a single request..."
          server.start
        end
      end

      app = find_or_create_app(args[:application_id])
      host_name = ENV.fetch("RAILS_HOST_NAME", "localhost:3000")
      redirect_uri = args.fetch(:redirect_uri, app.redirect_uri.split("\n").first)

      server_thread = start_callback_server if redirect_uri.include?("localhost:3001")

      params = {
        client_id: app.uid,
        client_secret: app.secret,
        redirect_uri: redirect_uri,
        response_type: "code",
        prompt: args[:prompt],
        scope: app.scopes
      }.compact.map { |key, value| "#{key}=#{value}" }.join("&")

      sh "xdg-open 'http://#{host_name}/oauth/authorize?#{params}'"

      server_thread.join if server_thread
    end
  end

  namespace :local do
    desc "Create a local user with admin-permissions"
    task admin: :environment do
      abort("This is for development purposes only.") unless Rails.env.development?
      abort("This needs at least one wagon to work") if Wagons.all.blank?
      abort("This needs a group-structure to work") if Group.subclasses.blank?

      username = "tester@example.net"
      password = "hitobito is the best software to manage people in complex group hierarchies"

      me = Person.find_by(email: username) ||
        Person.new(first_name: "Tom", last_name: "Tester",
          email: username, birthday: "1970-01-01")

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
        me.two_fa_secret = %w[
          2R7IGBJMSZV1L7TPLDI8HDO0UD8LCQ6NMVJWDYKW6I8XXM9RGU6G4II9KOJ2O8J6NUV
          BM4DUGAKQ0EL41TVR1BKN5YHA5IVATD58BWZTQ0T46X85ED2HQ9CYZCAQYK0JMXOSKN
          DZNEUSG5ZCS9ZURT7LB7HGK1AXD350LT9Q4PYO8ZX4ZDSCZF96N4LWFOH4C92DJ2NV
        ].join
        me.two_factor_authentication = "totp"
        me.save!(validate: false)

        tmp_dir = Pathname.new("tmp")
        tmp_dir.mkpath
        qr_code = tmp_dir.join("tom-tester-otp.png")
        qr_code.delete if qr_code.exist?

        otp = People::OneTimePassword.new(me.two_fa_secret, person: me)
        otp.provisioning_qr_code.save(qr_code.to_s)

        case ENV.fetch("TERM", nil)
        when "xterm-kitty"
          puts "This is the QR-Code for the TOTP/2FA-Setup"
          system("kitty +kitten icat #{qr_code}")
        else
          puts "The QR-Code for TOTP/2FA-Setup is located at #{qr_code}"
        end

        puts "If you have setup 2FA for a dev-hitobito already, you may ignore this"
        puts "as the generated codes should be the same."
        puts
      end

      unless me.valid?
        puts "This person has invalid data for this wagon. Nothing serious, just keep"
        puts "in mind: You need to fill additional fields if you update it."
        puts
      end

      puts "Done."
    end

    if Rails.env.development?
      desc "Reset root user pw to known dev value"
      task reset_root_pw: :environment do
        root = Person.root
        root.password = "hito42bito"
        root.encrypted_two_fa_secret = nil
        root.two_factor_authentication = nil
        root.save!(validate: false)
      end
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

task "bin/version": ["app/domain/release_version.rb"] do |file|
  content = Pathname.new(file.name).read

  start_marker = "### RELEASE_VERSION_CODE START"
  end_marker = "### RELEASE_VERSION_CODE END"
  pattern = /(.*)#{start_marker}.*#{end_marker}(.*)/m

  matches = content.match(pattern)

  before = matches[1]
  lib = Pathname.new(file.prerequisites.first).read
  after = matches[2]

  Pathname.new(file.name).open("w") do |f|
    f << before
    f << "#{start_marker}\n"
    f << lib
    f << end_marker
    f << after
  end
end
file "app/domain/release_version.rb"
