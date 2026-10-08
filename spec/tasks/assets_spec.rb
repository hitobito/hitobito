# frozen_string_literal: true

#  Copyright (c) 2026, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require "rake"

describe "assets rake tasks" do
  # rspec does not load rake tasks, and :environment is already booted by the spec_helper.
  # The file is loaded as in the core and, a second time, inside the app: namespace that a wagon's
  # Rakefile puts the core tasks in.
  rake_file = Rails.root.join("lib", "tasks", "assets.rake").to_s
  %w[environment db:test:prepare assets:precompile assets:clobber].each do |name|
    Rake::Task.define_task(name)
  end
  load rake_file
  Rake.application.in_namespace("app") do
    %w[environment db:test:prepare assets:precompile assets:clobber].each do |name|
      Rake::Task.define_task(name)
    end
    load rake_file
  end

  let(:tmp) { Pathname.new(Dir.mktmpdir) }
  let(:rake_dsl) { TOPLEVEL_BINDING.receiver }
  let(:wagon_root) { tmp.join("hitobito_pbs") }
  let(:wagon) { double(wagon_name: "pbs", paths: double(path: wagon_root)) }
  let(:wagons) { [] }
  let(:current_wagon) { nil }

  before do
    Rake.application.tasks.each(&:reenable)
    allow(Rails).to receive(:root).and_return(tmp)
    allow(Wagons).to receive_messages(all: wagons, current_wagon: current_wagon)
    allow(rake_dsl).to receive(:sh)
    wagon_root.join("app", "assets", "stylesheets").mkpath
  end

  after do
    tmp.rmtree
    ENV.delete("WAGON_MANIFEST_DIR")
  end

  def manifest_dir(composition)
    tmp.join("tmp", "wagon_manifests", composition)
  end

  def manifest(composition, name)
    JSON.parse(manifest_dir(composition).join(name).read)
  end

  describe "assets:wagon_manifests" do
    it "writes the manifests of the core composition and points WAGON_MANIFEST_DIR at them" do
      Rake::Task["assets:wagon_manifests"].invoke

      expect(ENV["WAGON_MANIFEST_DIR"]).to eq manifest_dir("core").to_s
      expect(manifest("core", "css.json")).to eq("buildDir" => "core", "wagonStylesheetPaths" => [])
      expect(manifest("core", "js.json")).to eq("buildDir" => "core", "wagons" => [])
    end

    context "with a wagon" do
      let(:wagons) { [wagon] }

      it "writes the manifests of the wagon composition" do
        Rake::Task["assets:wagon_manifests"].invoke

        expect(ENV["WAGON_MANIFEST_DIR"]).to eq manifest_dir("pbs").to_s
        expect(manifest("pbs", "css.json")).to eq(
          "buildDir" => "pbs",
          "wagonStylesheetPaths" => [wagon_root.join("app", "assets", "stylesheets").to_s]
        )
        expect(manifest("pbs", "js.json")["wagons"].pluck("name")).to eq ["pbs"]
      end
    end
  end

  describe "assets:build" do
    it "runs yarn in the core directory" do
      Rake::Task["assets:build"].invoke

      expect(rake_dsl).to have_received(:sh).with("yarn", "install", chdir: tmp.to_s)
      expect(rake_dsl).to have_received(:sh).with("yarn", "build:css", chdir: tmp.to_s)
      expect(rake_dsl).to have_received(:sh).with("yarn", "build", chdir: tmp.to_s)
    end

    it "honours the skip flags" do
      with_env("SKIP_YARN_INSTALL" => "1", "SKIP_CSS_BUILD" => "1") do
        Rake::Task["assets:build"].invoke
      end

      expect(rake_dsl).to have_received(:sh).once
      expect(rake_dsl).to have_received(:sh).with("yarn", "build", chdir: tmp.to_s)
    end
  end

  describe "assets:build_for_test" do
    let(:wagons) { [wagon] }

    it "builds the core composition in the core, whatever wagons are loaded" do
      Rake::Task["assets:build_for_test"].invoke

      expect(ENV["WAGON_MANIFEST_DIR"]).to eq manifest_dir("core").to_s
      expect(manifest("core", "js.json")["wagons"]).to be_empty
      expect(rake_dsl).to have_received(:sh).with("yarn", "build", chdir: tmp.to_s)
    end

    context "in a wagon" do
      let(:current_wagon) { wagon }

      it "builds the wagon composition" do
        Rake::Task["app:assets:build_for_test"].invoke

        expect(ENV["WAGON_MANIFEST_DIR"]).to eq manifest_dir("pbs").to_s
        expect(rake_dsl).to have_received(:sh).with("yarn", "build", chdir: tmp.to_s)
      end
    end

    it "runs after db:test:prepare in the core" do
      Rake::Task["db:test:prepare"].invoke

      expect(ENV["WAGON_MANIFEST_DIR"]).to eq manifest_dir("core").to_s
      expect(rake_dsl).to have_received(:sh).with("yarn", "build", chdir: tmp.to_s)
    end

    context "in a wagon" do
      let(:current_wagon) { wagon }

      it "runs after db:test:prepare" do
        Rake::Task["app:db:test:prepare"].invoke

        expect(ENV["WAGON_MANIFEST_DIR"]).to eq manifest_dir("pbs").to_s
        expect(rake_dsl).to have_received(:sh).with("yarn", "build", chdir: tmp.to_s)
      end
    end
  end

  describe "assets:precompile" do
    it "builds the assets first" do
      Rake::Task["assets:precompile"].invoke

      expect(rake_dsl).to have_received(:sh).with("yarn", "build", chdir: tmp.to_s)
    end
  end

  describe "assets:clobber" do
    it "removes the builds of all compositions but keeps the directory" do
      builds = tmp.join("app", "assets", "builds")
      builds.join("core").mkpath
      builds.join("core", "application.css").write("")
      builds.join(".keep").write("")

      Rake::Task["assets:clobber"].invoke

      expect(builds.children).to eq [builds.join(".keep")]
    end
  end

  def with_env(values)
    previous = values.keys.index_with { |key| ENV[key] }
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    previous.each { |key, value| ENV[key] = value }
  end
end
