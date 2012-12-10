module Export::CsvPeople
  # adds social_accounts and company related attributes
  class PeopleFull < PeopleAddress
    
    EXCLUDED_ATTRS = %w(id
                        contact_data_visible
                        created_at
                        creator_id
                        updated_at
                        updater_id
                        encrypted_password
                        reset_password_token
                        reset_password_sent_at
                        remember_created_at
                        sign_in_count
                        current_sign_in_at
                        last_sign_in_at
                        current_sign_in_ip
                        last_sign_in_ip
                        picture
                        last_label_format_id)
    
    def attributes
      (model_class.column_names - EXCLUDED_ATTRS).collect(&:to_sym)
    end

    def add_associations
      super
      merge!(labels(people.map(&:social_accounts), Accounts.social_accounts))
    end
  end
end