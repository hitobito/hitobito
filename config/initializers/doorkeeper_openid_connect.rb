Doorkeeper::OpenidConnect.configure do
  issuer Settings.oidc.issuer

  # $>openssl genrsa 2048
  #   signing_key <<-EOL
  # -----BEGIN RSA PRIVATE KEY-----
  # ....
  # -----END RSA PRIVATE KEY-----
  # EOL

  signing_key Settings.oidc.signing_key.join.presence

  subject_types_supported [:public]

  resource_owner_from_access_token do |access_token|
    # Example implementation:
    # User.find_by(id: access_token.resource_owner_id)
    Person.find_by(id: access_token.resource_owner_id)
  end

  auth_time_from_resource_owner do |resource_owner|
    # Example implementation:
    # resource_owner.current_sign_in_at
  end

  reauthenticate_resource_owner do |resource_owner, return_to|
    # Example implementation:
    # store_location_for resource_owner, return_to
    # sign_out resource_owner
    # redirect_to new_user_session_url
  end

  subject do |resource_owner, application|
    # Example implementation:
    # resource_owner.id
    resource_owner.id

    # or if you need pairwise subject identifier, implement like below:
    # Digest::SHA256.hexdigest("#{resource_owner.id}#{URI.parse(application.redirect_uri).host}#{'your_secret_salt'}")
  end

  # Protocol to use when generating URIs for the discovery endpoint,
  # for example if you also use HTTPS in development
  # protocol do
  #   :https
  # end

  # Expiration time on or after which the ID Token MUST NOT be accepted for processing. (default 120 seconds).
  # expiration 600

  # Example claims:
  # claims do
  #   normal_claim :_foo_ do |resource_owner|
  #     resource_owner.foo
  #   end

  #   normal_claim :_bar_ do |resource_owner|
  #     resource_owner.bar
  #   end
  # end

  claims do
    claim(:email, scope: :email)     { |resource_owner| resource_owner.email }
    claim(:first_name, scope: :name) { |resource_owner| resource_owner.first_name }
    claim(:last_name, scope: :name)  { |resource_owner| resource_owner.last_name }
    claim(:nickname, scope: :name)   { |resource_owner| resource_owner.nickname }
    claim(:address, scope: :name)    { |resource_owner| resource_owner.address }
    claim(:zip_code, scope: :name)   { |resource_owner| resource_owner.zip_code }
    claim(:town, scope: :name)       { |resource_owner| resource_owner.town }
    claim(:country, scope: :name)    { |resource_owner| resource_owner.country }

    claim(:roles, scope: :with_roles) do |resource_owner|
      resource_owner.roles.includes(:group).collect do |role|
        {
          group_id: role.group_id,
          group_name: role.group.name,
          role: role.class.model_name,
          role_name: role.class.model_name.human
        }
      end
    end
  end
end
