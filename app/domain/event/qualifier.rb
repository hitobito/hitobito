# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Event::Qualifier

  def self.for(participation)
    qualifier_class(participation).new(participation)
  end

  def self.leader_types(event)
    event.class.role_types.select(&:leader?)
  end

  private

  def self.qualifier_class(participation)
    if leader?(participation)
      Event::Qualifier::Leader
    else
      Event::Qualifier::Participant
    end
  end


  def self.leader?(participation)
    participation.roles.where(type: leader_types(participation.event).map(&:sti_name)).exists?
  end

end
