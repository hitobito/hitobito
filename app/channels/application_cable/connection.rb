module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_person

    def connect
      set_current_person || reject_unauthorized_connection
    end

    private

    def set_current_person
      if (authenticated_person = env["warden"].user(:person))
        self.current_person = authenticated_person
      end
    end
  end
end
