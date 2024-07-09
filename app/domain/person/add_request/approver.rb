#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Person::AddRequest::Approver
  def self.for(request, current_user)
    name = request.class.name.demodulize
    klass = "Person::AddRequest::Approver::#{name}".constantize
    klass.new(request, current_user)
  end
end
