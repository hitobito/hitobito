# frozen_string_literal: true

class UpgradeSessionsToSecureStorage < ActiveRecord::Migration[6.1]
  def up
    session_class = ActionDispatch::Session::ActiveRecordStore.session_class

    say_with_time('deleting sessions...') { session_class.delete_all }
    say_with_time('securing sessions...') { session_class.find_each(&:secure!) }
  end
end
