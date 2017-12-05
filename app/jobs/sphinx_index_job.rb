# encoding: utf-8

#  Copyright (c) 2012-2015, Puzzle ITC Gmbh. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class SphinxIndexJob < RecurringJob

  run_every Settings.sphinx.index.interval.minutes

  def perform_internal
    if sphinx_local?
      run_rebuild_task
    end
  end

  private

  def sphinx_local?
    Hitobito::Application.sphinx_local?
  end

  def reschedule
    sphinx_local? ? super : disable_job!
  end

  def disable_job!
    delayed_jobs.destroy_all
  end

  def run_rebuild_task
    Hitobito::Application.load_tasks
    Rake::Task['ts:rebuild'].invoke
  end

end
