# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito_swb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_swb.

module Fixtures
  class CustomContentsGenerator
    attr_reader :checksum_file, :seed_file, :contents_file, :translations_file, :action_texts_file

    def initialize
      @checksum_file = Rails.root.join("spec", "fixtures", ".custom_contents")
      @contents_file = Rails.root.join("spec", "fixtures", "custom_contents.yml")
      @action_texts_file = Rails.root.join("spec", "fixtures", "action_text", "rich_texts.yml")
      @translations_file = Rails.root.join("spec", "fixtures", "custom_content", "translations.yml")
      @seed_file = Rails.root.join("db", "seeds", "custom_contents.rb")
    end

    def run
      # return if current?

      generate_custom_contents
      generate_custom_content_translations
      generate_action_texts
      write_checksum
    end

    def current?
      checksum_file.exist? && checksum_file.read == md5sum(seed_file)
    end

    private

    def custom_contents
      @custom_contents ||= CustomContent.all.index_by(&:id)
    end

    def translations
      @translations ||= CustomContent::Translation.all.index_by(&:id)
    end

    def generate_custom_contents
      write_yaml(contents_file) do
        custom_contents.values.map do |content|
          [content.key, read_attributes(content, ignore: %w[body label subject])]
        end
      end
    end

    def generate_custom_content_translations
      write_yaml(translations_file) do
        translations.values.map do |translation|
          content = custom_contents[translation.custom_content_id]
          [[content.key, translation.locale].join("_"), read_attributes(translation)]
        end
      end
    end

    def generate_action_texts
      write_yaml(action_texts_file) do
        ActionText::RichText.includes(record: :custom_content).map do |text|
          key = custom_contents[text.record.custom_content_id]
          [[key, text.record.locale].join("_"), read_attributes(text).transform_values(&:to_s)]
        end
      end
    end

    def write_yaml(file)
      data = yield
      write(file, data.sort_by(&:first).to_h.to_yaml)
    end

    def write_checksum
      write(checksum_file, md5sum(seed_file))
    end

    def read_attributes(model, ignore: [])
      ignored = ignore + %w[id created_at updated_at]
      model.attributes.except(*ignored).compact_blank
    end

    def write(file, data)
      puts "writing #{file}"
      file.write(data)
    end

    def md5sum(file)
      Digest::MD5.hexdigest(file.read)
    end
  end
end
