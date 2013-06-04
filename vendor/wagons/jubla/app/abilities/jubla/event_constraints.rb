module Jubla::EventConstraints

  def not_closed_or_admin
    user_context.admin || !is_closed_course?
  end

  def at_least_one_group_not_deleted_and_not_closed_or_admin
    at_least_one_group_not_deleted && not_closed_or_admin
  end

  private

  def is_closed_course?
    event.kind_of?(Event::Course) && event.closed?
  end

end