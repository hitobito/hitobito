# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class DocumentationReader

  GITHUB_EMOJI_BASE_URL = 'https://github.githubassets.com/images/icons/emoji/unicode'
  GITHUB_EMOJIS = { 'bangbang' => '203c' }

  DOCUMENTATION_ROOT="#{Rails.root}/doc"

  class << self
    def html(md_path)
      DocumentationReader.new(md_path).html
    end
  end

  def initialize(md_path)
    @md_path = "#{md_path}.md"
  end

  def markdown
    file_path = "#{DOCUMENTATION_ROOT}/#{@md_path}"
    File.open(file_path).read
  end

  def html
    html = CommonMarker.render_html(markdown, :DEFAULT)
    insert_github_emojis(html)
    html += source_link
    html
  end

  private

  def insert_github_emojis(content)
    GITHUB_EMOJIS.each do |k,v|
      identifier = ":#{k}:"
      emoji_img = github_emoji_img(k, v)
      content.gsub!(identifier, emoji_img)
    end
  end

  def github_emoji_img(name, png_name)
    img_src = "#{GITHUB_EMOJI_BASE_URL}/#{png_name}.png"
    "<img src='#{img_src}' class='github-emoji' alt='#{name}' title='#{name}'/>"
  end

  def source_link
    github_src = "https://github.com/hitobito/hitobito/tree/master/doc/#{@md_path}"
    "\n<a href='#{github_src}' target='_blank'>Markdown source</a>"
  end

end
