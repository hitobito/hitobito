Doorkeeper::JWT.configure do
  # Set the payload for the JWT token. This should contain unique information
  # about the user. Defaults to a randomly generated token in a hash:
  #     { token: "RANDOM-TOKEN" }
  token_payload do |opts|
    app = opts[:application]
    person = Person.find(opts[:resource_owner_id])
    {
      iss: app.name,
      aud: app.additional_audiences.to_s.lines.map(&:strip).prepend(app.uid),
      iat: Time.current.utc.to_i,
      exp: Time.current.utc.to_i + Settings.oidc.access_token_expires_in,

      # @see JWT reserved claims - https://tools.ietf.org/html/draft-jones-json-web-token-07#page-7
      jti: SecureRandom.uuid,
      sub: person.id
    }
  end

  # Optionally set additional headers for the JWT. See
  # https://tools.ietf.org/html/rfc7515#section-4.1
  # JWK can be used to automatically verify RS* tokens client-side if token's kid matches a public kid in /oauth/discovery/keys
  token_headers do |_opts|
    key = OpenSSL::PKey::RSA.new(Settings.oidc.signing_key.join.presence)
    {kid: JWT::JWK.new(key, {kid_generator: ::JWT::JWK::Thumbprint})[:kid]}
  end

  # Use the application secret specified in the access grant token. Defaults to
  # `false`. If you specify `use_application_secret true`, both `secret_key` and
  # `secret_key_path` will be ignored.
  use_application_secret false

  # Set the signing secret. This would be shared with any other applications
  # that should be able to verify the authenticity of the token. Defaults to "secret".
  secret_key Settings.oidc.signing_key.join.presence

  # If you want to use RS* algorithms specify the path to the RSA key to use for
  # signing. If you specify a `secret_key_path` it will be used instead of
  # `secret_key`.
  # secret_key_path File.join("path", "to", "file.pem")

  # Specify cryptographic signing algorithm type (https://github.com/progrium/ruby-jwt). Defaults to
  # `nil`.
  signing_method :rs256
end
