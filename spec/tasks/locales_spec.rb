# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require "rake"

describe "locales:patch_de" do
  # The task overwrites *.de.yml in place, so it must never run on the real config/locales.
  # Instead the real locale files are copied into a temporary Rails.root.
  let(:core_locales) { Rails.root.join("config", "locales") }
  let(:tmp) { Pathname.new(Dir.mktmpdir) }
  let(:locale_dir) { tmp.join("config", "locales") }

  # rspec does not load rake tasks, and :environment is already booted by the spec_helper
  Rake::Task.define_task(:environment)
  Rake.application.rake_require("tasks/locales", [Rails.root.join("lib").to_s])

  subject(:task) { Rake::Task["locales:patch_de"] }

  before do
    task.reenable

    locale_dir.mkpath
    FileUtils.cp_r("#{core_locales}/.", locale_dir)
    locale_dir.glob("*.de_??.yml").each(&:delete) # variants are added per example

    allow(Rails).to receive(:root).and_return(tmp)
    allow(Wagons).to receive(:all).and_return([])
    allow(Settings.application).to receive(:german_variant).and_return("de_DE")
  end

  after { tmp.rmtree }

  def write_variant(locale, text)
    locale_dir.join("views.#{locale}.yml")
      .write("# comment header\n\n#{locale}:\n  global:\n    add: #{text}\n")
  end

  it "patches the de locale with the configured variant only" do
    write_variant("de_CH", "Hinzufügen")
    write_variant("de_DE", "Hinzufuegen")

    expect { task.invoke }.to change { locale_dir.join("views.de.yml").read }
      .to("# comment header\n\nde:\n  global:\n    add: Hinzufuegen\n")
  end

  it "does not touch the other locales" do
    write_variant("de_DE", "Hinzufuegen")
    others = locale_dir.glob("*.{fr,it,en}.yml") + [locale_dir.join("models.de.yml")]

    expect { task.invoke }.not_to change { others.map(&:read) }
  end

  it "does nothing if no file for the configured variant exists" do
    write_variant("de_CH", "Hinzufügen")

    expect { task.invoke }.not_to change { locale_dir.join("views.de.yml").read }
  end

  it "does nothing if no variant is configured" do
    allow(Settings.application).to receive(:german_variant).and_return(nil)
    write_variant("de_DE", "Hinzufuegen")

    expect { task.invoke }.not_to change { locale_dir.join("views.de.yml").read }
  end

  it "patches wagon locale files as well" do
    wagon_root = Pathname.new(Dir.mktmpdir)
    wagon_root.join("config", "locales").mkpath
    wagon_root.join("config", "locales", "wagon.de_DE.yml").write("de_DE:\n  foo: bar\n")
    allow(Wagons).to receive(:all).and_return([double(root: wagon_root)])

    task.invoke

    expect(wagon_root.join("config", "locales", "wagon.de.yml").read).to eq("de:\n  foo: bar\n")
  ensure
    wagon_root&.rmtree
  end
end
