# Forces all threads to share the same connection. This works on
# Capybara because it starts the web server in a thread.
# Allows us to use factories and transactional fixtures in capybara.
class ActiveRecord::Base
  mattr_accessor :shared_connection
  @@shared_connection = nil

  def self.connection
    @@shared_connection || retrieve_connection
  end
end
ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection
