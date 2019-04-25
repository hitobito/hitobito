namespace :dev do
  namespace :oauth do

    desc 'Obtain oauth access token'
    task :token, [:application_id, :redirect_uri, :code] => [:environment] do |_, args|
      app = Oauth::Application.find(args.fetch(:application_id))
      curl = <<-BASH
      curl -v -H 'Accept: application/json' -X POST -d 'grant_type=authorization_code'  \
      -d 'client_id=#{app.uid}' -d 'client_secret=#{app.secret}' \
      -d 'redirect_uri=#{args.fetch(:redirect_uri)}' -d 'code=#{args.fetch(:code)}' \
      http://localhost:3000/oauth/token
      BASH
      sh curl.strip_heredoc
    end

    desc 'Introspect oauth token'
    task :introspect, [:access_token, :token] do |_, args|
      access_token = args.fetch(:access_token)
      token = args.fetch(:token, access_token)
      curl = <<-BASH
      curl -v -H 'Accept: application/json' \
      -H 'Authorization: Bearer #{access_token}' \
      -d 'token=#{token}' \
      http://localhost:3000/oauth/introspect
      BASH
      sh curl.strip_heredoc
    end

    desc 'Obtain profile information'
    task :profile, [:access_token, :scope] do |_, args|
      access_token = args.fetch(:access_token)
      curl = <<-BASH
      curl -v -H 'Accept: application/json' \
      -H 'Authorization: Bearer #{access_token}' \
      -H 'X-Scope: #{args[:scope]}' \
      http://localhost:3000/oauth/profile
      BASH
      sh curl.strip_heredoc
    end
  end
end
