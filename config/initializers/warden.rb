# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# https://redmine.puzzle.ch/issues/3613
#
# Devise modules (rememberable, trackable) use save to update fields.
# This automatically also updates updated_at field.
#
# We use warden hooks to disable automatic updating of timestamps when
# user logs into and logs out of application.

Warden::Manager.prepend_after_set_user :except => :fetch do |record, warden, options|
  record.define_singleton_method(:record_timestamps, Proc.new { false } )
end

Warden::Manager.prepend_before_logout do |record, warden, options|
  record.define_singleton_method(:record_timestamps, Proc.new { false } )
end
