# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

if defined? Bullet
  Bullet.enable = true
  Bullet.alert = true
  Bullet.bullet_logger = true
  Bullet.rails_logger  = true

  # groups loaded for current user
  Bullet.add_whitelist type: :unused_eager_loading, class_name: 'Person', association: :groups
  Bullet.add_whitelist type: :unused_eager_loading, class_name: 'Person', association: :roles

  # answers for event::participations

  # EventKind may not be eager loaded if some event types have kind and others not.
  Bullet.add_whitelist type: :n_plus_one_query, class_name: 'Event::Course', association: :kind

  # event, :person and roles for participation list
  [:application, :answers, :event, :person, :roles].each do |assoc|
    Bullet.add_whitelist type: :unused_eager_loading, class_name: 'Event::Participation', association: assoc
  end

  Bullet.add_whitelist type: :unused_eager_loading, class_name: 'Event::Kind', association: :translations

  # Event::Participation decorator informs marks participants with incomplete answers on participations lists
  Bullet.add_whitelist type: :unused_eager_loading, class_name: 'Event::Answer', association: :question
end
