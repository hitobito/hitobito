# This rake task was added by annotate_rb gem.

# Can set `ANNOTATERB_SKIP_ON_DB_TASKS` to be anything to skip this
if ENV["ANNOTATERB_SKIP_ON_DB_TASKS"].nil? && Wagons.all.none?
  require "annotate_rb"

  AnnotateRb::Core.load_rake_tasks
end
