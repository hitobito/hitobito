class ErrorPageGenerator < Rails::Generators::NamedBase

  desc "Generate a static error page based on the layout."

  def generate_page
    ENV['RAILS_GROUPS'] = 'assets'

    error = if file_name =~ /^\d{3}$/
      file_name
    else
      Rack::Utils::SYMBOL_TO_STATUS_CODE[file_name.to_sym]
    end

    run "rm -f public/#{error}.html"
    request = Rack::MockRequest.env_for "/#{error}"
    request['action_dispatch.exception'] = StandardError.new 'generator'
    status, headers, body = *Hitobito::Application.call(request)
    create_file "public/#{error}.html", body.join, force: true
  end

end