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

Warden::Strategies.add(:one_time_token_authenticatable, Devise::Strategies::OneTimeTokenAuthenticatable)
