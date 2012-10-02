
# Monkey patch until newer version of paranoia comes out (> 1.1.0)
class ActiveRecord::Base
  def persisted?
    paranoid? ? !new_record? : super
  end
end