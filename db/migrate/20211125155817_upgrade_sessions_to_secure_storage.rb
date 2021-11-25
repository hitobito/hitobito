# frozen_string_literal: true

class UpgradeSessionsToSecureStorage < ActiveRecord::Migration[6.1]
  def up
    say_with_time('securing sessions...') do
      ActionDispatch::Session::ActiveRecordStore.session_class.find_each(&:secure!)
    end
  end
end
