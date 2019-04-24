module Oauth
  class Application < Doorkeeper::Application
    def to_s
      name
    end
  end
end
