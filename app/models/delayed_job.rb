class DelayedJob < ActiveRecord::Base
  has_one :user_job_result
end
