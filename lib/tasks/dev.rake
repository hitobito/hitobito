namespace :dev do

  desc 'Obtain oauth token'
  task :oauth_token, [:application_id, :redirect_uri, :code] => [:environment] do |_, args|
    app = Oauth::Application.find(args.fetch(:application_id))
    curl = <<-BASH
      curl -H 'Accept: application/json' -X POST -d 'grant_type=authorization_code'  \
      -d 'client_id=#{app.uid}' -d 'client_secret=#{app.secret}' \
      -d 'redirect_uri=#{args.fetch(:redirect_uri)}' -d 'code=#{args.fetch(:code)}' \
      http://localhost:3000/oauth/token
    BASH
    sh curl.strip_heredoc
  end

  desc 'Use token to obtain info'
  task :oauth_token_info, [:token] do |_, args|
    curl = <<-BASH
      curl -H 'Accept: application/json' \
      -H 'Authorization: Bearer #{args.fetch(:token)}' \
      http://localhost:3000/oauth/token/info
    BASH
    sh curl.strip_heredoc
  end
end
