# frozen_string_literal: true

#  Copyright (c) 2020-2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Release
  # lowlevel tooling
  module Lowlevel
    private

    def branch(name)
      notify "switching to branch #{name}"
      execute "git checkout #{name}"
    end

    def fast_forward(name)
      remote = `git remote | head -n 1`.chomp
      execute "git merge --ff-only #{remote}/#{name}"
    end

    def add(files)
      notify "staging files"
      execute "git add -v #{files}"
    end

    def commit(message)
      notify "committing"
      with_env({"SKIP" => "RuboCop,UpdatedLicenseHeader"}) do
        execute "git commit -m '#{message}'"
      end
    end

    def fix_submodules
      notify "reparing submodules"
      execute "git submodule init && git submodule sync && git submodule update"
    end

    def submodules(action)
      notify "executing '#{action}' in all submodules"
      execute "git submodule foreach '#{action}'"
    end

    def submodule_status
      notify "submodule status"
      execute "git submodule status"
    end

    # rubocop:disable Metrics/MethodLength
    def retry_with_reset(max_attempts: 5, &block)
      attempt = 1

      begin
        yield
      rescue => e
        if attempt >= max_attempts
          notify "Failed after #{max_attempts} attempts: #{e.message}"
          raise e
        end

        notify "Attempt #{attempt} failed: #{e.message}. Resetting to upstream and retrying..."
        execute "git reset --hard @{u}"

        sleep_time = 2**attempt
        notify "Waiting #{sleep_time} seconds before retry..."
        sleep(sleep_time)

        attempt += 1
        retry
      end
    end
    # rubocop:enable Metrics/MethodLength

    def tag(name)
      notify "tagging #{name}"
      execute "git tag -f #{name}"
    end

    def push
      notify "pushing code and tags"
      confirm_and_execute "git push origin && git push origin --force --tags"
    end
  end
end
