# frozen_string_literal: true

#  Copyright (c) 2023-2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require_relative './highlevel'
require_relative './lowlevel'
require_relative './tooling'

module Release
  module Commands
    # rubocop:disable Metrics/BlockLength,Metrics/MethodLength,Metrics/AbcSize
    def update_production
      with_env({ 'OVERCOMMIT_DISABLE' => '1' }) do
        in_dir(hitobito_group_dir) do
          notify "Releasing #{@all_wagons.join(', ')}"
          notify @message

          in_dir('hitobito') do
            break if existing_version_again?

            update_translations
            update_changelog
            update_version file: 'VERSION'

            release_version @version
          end

          @all_wagons.each do |wagon|
            in_dir("hitobito_#{wagon}") do
              break if existing_version_again?

              update_translations
              update_changelog
              update_version file: "lib/hitobito_#{wagon}/version.rb"
              release_version @version
            end
          end

          in_dir(composition_repo_dir) do
            unless working_in_composition_dir?
              fetch_code_and_tags
              update_submodules(branch: 'production')
            end

            update_submodule_content(to: @version)
            record_submodule_state
            release_version @version
          end
        end
      end
    end

    def update_integration
      with_env({ 'OVERCOMMIT_DISABLE' => '1' }) do
        in_dir(hitobito_group_dir) do
          notify "Updating #{@all_wagons.join(', ')}"
          notify @message

          ['hitobito', *(@all_wagons.map { |wgn| "hitobito_#{wgn}" })].each do |dir|
            in_dir(dir) do
              update_translations
              upload_translation_sources
              push
            end
          end

          in_dir(composition_repo_dir) do
            unless working_in_composition_dir?
              fetch_code_and_tags
              update_submodules(branch: 'devel')
            end

            record_submodule_state
            release_version @version
          end
        end
      end
    end
    # rubocop:enable Metrics/BlockLength,Metrics/MethodLength,Metrics/AbcSize
  end
end
