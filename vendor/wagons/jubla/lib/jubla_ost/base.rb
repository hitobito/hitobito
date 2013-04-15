module JublaOst
  class Base < ActiveRecord::Base
    self.abstract_class = true

    establish_connection JublaOst::Config.database

    def migrate
      ActiveRecord::Base.record_timestamps = false
      ActiveRecord::Base.transaction do
        JublaOst::Region.migrate
      end
      ActiveRecord::Base.record_timestamps = true
    end
  end
end