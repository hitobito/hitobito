# frozen_string_literal: true

#  Copyright (c) 2022-2024, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class DocumentationReader

  GITHUB_DEV_DOC_BASE_URL = 'https://github.com/hitobito/hitobito/tree/master/doc/development'
  DOCUMENTATION_ROOT = Rails.root.join('doc').to_s

  class << self
    def html(md_path)
      new(md_path).html
    end
  end

  def initialize(md_path)
    @md_path = "#{md_path}.md"
  end

  def markdown
    file_path = "#{DOCUMENTATION_ROOT}/#{@md_path}"
    markdown = File.read(file_path)
    absolutize_github_links(markdown)
    markdown
  end

  def html
    html = Commonmarker.to_html(markdown,
                                plugins: { syntax_highlighter: nil },
                                options: {
                                  render: { gemojis: true },
                                  extensions: { table: true }
                                })
    style_tables(html)
    html += source_link
    html
  end

  private

  def absolutize_github_links(markdown)
    regex = /]\((.+\.md)\)/
    links = markdown.scan(regex).flatten
    links.each do |link|
      markdown.gsub!(link, "#{GITHUB_DEV_DOC_BASE_URL}/#{link}")
    end
    markdown
  end

  def style_tables(html)
    table_tag = '<table>'
    styled_table_tag = '<table class="table table-striped table-bordered">'
    html.gsub!(table_tag, styled_table_tag)
  end

  def source_link
    github_src = "https://github.com/hitobito/hitobito/tree/master/doc/#{@md_path}"
    "\n<a href='#{github_src}' target='_blank'>Markdown source</a>"
  end

end
