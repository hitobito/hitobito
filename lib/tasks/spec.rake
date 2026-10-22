# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

if defined?(RSpec::Core::RakeTask)
  # SPEC_GROUP=2/3 runs the second third of the groups of similar size parallel_tests splits the
  # spec files into, one process per CPU. Exits 2 on errors outside of examples, e.g. pending specs.
  def parallel_rspec(*args, rspec_opts)
    require "parallel_tests"
    group, groups = ENV.fetch("SPEC_GROUP", "1/1").split("/").map(&:to_i)
    processes = ParallelTests.determine_number_of_processes(nil)
    system("parallel_rspec", "-n", (processes * groups).to_s,
      "--only-group", (((group - 1) * processes + 1)..(group * processes)).to_a.join(","),
      "--highest-exit-status", "--serialize-stdout", "--combine-stderr",
      "-o", "--error-exit-code 2 #{rspec_opts}", *args, "spec")
  end

  namespace :spec do
    desc "Run the specs without features of SPEC_GROUP in one process per CPU"
    task :without_features_group_parallel do # rubocop:disable Rails/RakeEnvironment
      abort unless parallel_rspec("--exclude-pattern", "spec/features/",
        "--tag ~type:feature --format progress")
    end

    namespace :features do
      desc "Run feature specs of SPEC_GROUP in one process per CPU, rerun failed examples twice"
      task :lenient_parallel do # rubocop:disable Rails/RakeEnvironment
        failures = "tmp/failing_specs.log"
        log_failures = %W[--require parallel_tests/rspec/failures_logger
          --format ParallelTests::RSpec::FailuresLogger --out #{failures}]

        puts "\nFIRST ATTEMPT\n"
        passed = parallel_rspec("--pattern", "spec/features/",
          "--tag type:feature --format Fivemat #{log_failures.join(" ")}")

        %w[SECOND LAST].each do |attempt|
          break if passed
          abort if $CHILD_STATUS.exitstatus != 1

          examples = File.read(failures).gsub(/\e\[[\d;]*m/, "").scan(/^rspec (\S+)/).flatten
          abort "No failed examples found in #{failures}" if examples.empty?

          puts "\n#{attempt} ATTEMPT\n"
          passed = system("rspec", "--error-exit-code", "2", "--format", "Fivemat",
            *log_failures, *examples)
        end
        abort unless passed
      end
    end
  end
end

if Rake::Task.task_defined?("spec:features") # only if current environment knows rspec
  Rake::Task["spec:features"].actions.clear

  namespace :spec do
    RSpec::Core::RakeTask.new(:without_features) do |t|
      t.pattern = "./spec/**/*_spec.rb"
      t.rspec_opts = "--tag ~type:feature --format Fivemat"
    end

    RSpec::Core::RakeTask.new(:features) do |t|
      t.pattern = "./spec/features/**/*_spec.rb"
      t.rspec_opts = "--tag type:feature --format Fivemat"
    end

    spec_dirs = Pathname.new("spec").children.select(&:directory?).map(&:basename).map(&:to_s)
    (spec_dirs - %w[
      features
      fabricators fixtures
      support
      coverage reports
    ]).each do |dir|
      Rake::Task["spec:#{dir}"].actions.clear

      RSpec::Core::RakeTask.new(dir) do |t|
        t.pattern = "./spec/#{dir}/**/*_spec.rb"
        t.rspec_opts = "--format Fivemat"
      end
    rescue RuntimeError
      nil
    end

    namespace :features do
      # see https://www.puzzle.ch/de/blog/articles/2021/01/18/a-lenient-capybara
      desc "Run feature specs at most three times to gracefully handle flaky specs"
      task :lenient do |t| # rubocop:disable Rails/RakeEnvironment
        sh "rm -f tmp/examples.txt"
        puts "\nFIRST ATTEMPT\n"
        Rake::Task[t.name.gsub("lenient", "start")].invoke
        next if $CHILD_STATUS.exitstatus.zero?

        puts "\nSECOND ATTEMPT\n"
        Rake::Task[t.name.gsub("lenient", "retry")].invoke
        next if $CHILD_STATUS.exitstatus.zero?

        puts "\nLAST ATTEMPT\n"
        Rake::Task[t.name.gsub("lenient", "last")].invoke
      end

      RSpec::Core::RakeTask.new("start") do |t|
        t.pattern = "./spec/features/**/*_spec.rb"
        t.rspec_opts = "--tag type:feature --format Fivemat"
        t.fail_on_error = false # don't stop the whole run
      end
      RSpec::Core::RakeTask.new("retry") do |t|
        t.rspec_opts = "--only-failures --format Fivemat"
        t.fail_on_error = false # don't stop the whole run
      end
      RSpec::Core::RakeTask.new("last") do |t|
        t.rspec_opts = "--only-failures --format Fivemat"
        t.fail_on_error = true # do fail the run
      end
    end
  end
end
