# frozen_string_literal: true

Fabricator(:user_job_result) do
  person_id { ActiveRecord::FixtureSet.identify(:top_leader) }
  job_class { "TestJob" }
  filename { "subscriptions_to-blorbaels-rants" }
  filetype { "txt" }
  reports_progress { false }
end
