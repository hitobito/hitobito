class AddSharingTokenToEvents < ActiveRecord::Migration[6.0]
  def change
    add_column :events, :shared_access_token, :string, null: true
    add_index :events, :shared_access_token

    Event.reset_column_information
    Event::Course.reset_column_information

    reversible do |dir|
      dir.up do
        say_with_time 'prefilling all event with a new shared_access_token' do
          Event.find_each do |e|
            e.update_attribute(:shared_access_token, Devise.friendly_token)
          end
        end
      end
    end
  end
end
