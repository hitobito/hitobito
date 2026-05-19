# frozen_string_literal: true

class MailConfig
  MAIL_CONFIG_PATH = Rails.root.join("config", "mail.yml")

  class << self
    def legacy?
      config_file.blank?
    end

    def retriever_imap?
      config_file.present? &&
        retriever_imap[:address].present?
    end

    def retriever_imap
      @retriever_imap ||= retriever_imap_config
    end

    def retrieval_active?
      retriever_imap? &&
        retriever_imap.fetch(:interval, 0) != 0
    end

    private

    def retriever_imap_config
      config_file[:imap]
        .then { |config| decode_password(config) }
        .tap { |config| config[:interval] ||= config[:retriever_interval] }
    end

    def decode_password(config)
      if config[:password].present?
        config[:password] = Base64.decode64(config[:password])
      end
      config
    end

    def config_file
      @config_file ||= load_file.freeze
    end

    def load_file
      return nil unless File.exist?(MAIL_CONFIG_PATH)

      YAML.safe_load_file(MAIL_CONFIG_PATH).try(:deep_symbolize_keys)
    end
  end
end
