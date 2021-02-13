# encoding: utf-8

#  Copyright (c) 2015, Pascal Zumkehr. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Hitobito
  class DocGenerator
    attr_reader :title, :dir

    def initialize(dir, title)
      require "redcarpet"
      @dir = dir
      @title = title
    end

    def compose
      markdown = read_markdown_files
      html = build_document(markdown)
      write_html_file(html)
      copy_assets
    end

    def read_markdown_files
      files = Dir[Rails.root.join("doc", dir, "*_*.md")].sort
      files.collect { |f| File.read(f) }.join("\n")
    end

    def build_document(markdown)
      html = File.read(Rails.root.join("doc", "template", "skeleton.html"))
      html.gsub!("{title}", title)
      html.gsub!("{toc}", generate_toc(markdown))
      html.gsub!("{content}", generate_html(markdown))
      html.gsub!("<table>", '<table class="table table-striped">')
      html.gsub!(/<nav class='nav-left'>(.*?)<ul>/m,
        "<nav class='nav-left'>\\1<ul class='nav-left-list'>")
      html
    end

    def write_html_file(html)
      file = Rails.root.join("doc", dir, "#{dir}.html")
      File.write(file, html)
    end

    def copy_assets
      assets = Rails.root.join("doc", dir, "assets")
      FileUtils.mkdir_p(assets)
      FileUtils.cp(Dir[Rails.root.join("doc", "template", "*.{css,png}")], assets)
    end

    def generate_html(markdown)
      Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(with_toc_data: true),
        tables: true,
        no_intra_emphasis: true).render(markdown)
    end

    def generate_toc(markdown)
      Redcarpet::Markdown.new(Redcarpet::Render::HTML_TOC).render(markdown)
    end
  end
end

namespace :doc do
  desc "Generate the architecture documentation as HTML"
  task :arch do
    Hitobito::DocGenerator.new("architecture", "Architektur Dokumentation").compose
  end

  desc "Generate the development documentation as HTML"
  task :dev do
    Hitobito::DocGenerator.new("development", "Entwicklungs Dokumentation").compose
  end

  desc "Generate the all documentations"
  task all: [:arch, :dev]
end
