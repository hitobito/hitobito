module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_person

    def connect
      set_current_person || reject_unauthorized_connection
    end

    private

    def set_current_person
      authenticated_person = catch(:warden) { env["warden"].user(:person) }
      self.current_person = authenticated_person if authenticated_person.is_a?(Person)
    end
  end
end
