# encoding: utf-8

#  Copyright (c) 2015, Pascal Zumkehr. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

namespace :doc do
  desc 'Generate the architecture documentation as HTML'
  task :arch do
    compose_docs('architecture', 'Architektur Dokumentation')
  end

  def compose_docs(dir, title)
    require 'redcarpet'

    markdown = read_markdown_files(dir)
    html = build_document(markdown, title)
    write_html_file(html, dir)
    copy_assets(dir)
  end

  def read_markdown_files(dir)
    files = Dir[Rails.root.join('doc', dir, '*_*.md')].sort
    files.collect { |f| File.read(f) }.join("\n")
  end

  def build_document(markdown, title)
    html = File.read(Rails.root.join('doc', 'template', 'skeleton.html'))
    html.gsub!('{title}', title)
    html.gsub!('{toc}', generate_toc(markdown))
    html.gsub!('{content}', generate_html(markdown))
    html.gsub!('<table>', '<table class="table table-striped">')
    html.gsub!(/<nav class='nav-left'>(.*?)<ul>/m,
               "<nav class='nav-left'>\\1<ul class='nav-left-list'>")
    html
  end

  def write_html_file(html, dir)
    file = Rails.root.join('doc', dir, "#{dir}.html")
    File.write(file, html)
  end

  def copy_assets(dir)
    assets = Rails.root.join('doc', dir, 'assets')
    FileUtils.mkdir_p(assets)
    FileUtils.cp(Dir[Rails.root.join('doc', 'template', '*.{css,png}')], assets)
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
