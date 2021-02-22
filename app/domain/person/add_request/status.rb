#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Person::AddRequest::Status
  def self.for(person_id, body_type, body_id)
    type = begin
             "Person::AddRequest::Status::#{body_type}".constantize
           rescue
             nil
           end

    if type.nil?
      raise ActiveRecord::RecordNotFound, "No person add request for '#{body_type}' found"
    end

    type.new(person_id, body_id)
  end
end
