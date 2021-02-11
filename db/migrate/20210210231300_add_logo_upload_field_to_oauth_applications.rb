class AddLogoUploadFieldToOauthApplications < ActiveRecord::Migration[6.0]
  def change
    add_column :oauth_applications, :logo, :string
  end
end
