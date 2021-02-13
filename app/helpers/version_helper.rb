# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module VersionHelper

  def app_version_links(url="https://github.com/hitobito/%s/commits/%s")
    links = Hitobito::Application.versions.collect do |line|
      commit, submodule, _ = line.split(" ")
      content_tag(:li) do
        path = format(url % [submodule, commit.gsub(/[+|-]/, "")])
        link = link_to(commit[0..7], path, target: :_blank)

        "#{submodule} (#{link})".html_safe
      end
    end
    content_tag(:ul, safe_join(links))
  end

  def app_version_changelog_link
    if app_version
      link_to app_version, changelog_path
    end
  end

  private

  def app_version
    app_version = Wagons.app_version.to_s
    return unless app_version > "0.0"
    ["Version", app_version, Hitobito::Application.build_info].compact.join(" ")
  end

end
