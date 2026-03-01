#  Copyright (c) 2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Passes
  # Registry for pass template bundles.
  # Each template key maps to a Template struct containing the pdf_class,
  # verify_partial, and wallet_data_provider used to render a pass.
  #
  # Full implementation in WP 1a (#3989). This is the minimal skeleton
  # required by PassDefinition's template_key validation.
  module TemplateRegistry
    Template = Data.define(:key, :pdf_class, :verify_partial, :wallet_data_provider)

    class << self
      def register(key, pdf_class:, verify_partial:, wallet_data_provider:)
        registry[key.to_s] = Template.new(
          key: key.to_s,
          pdf_class: pdf_class,
          verify_partial: verify_partial,
          wallet_data_provider: wallet_data_provider
        )
      end

      def fetch(key)
        registry.fetch(key.to_s) do
          raise KeyError, "Unknown pass template key: #{key.inspect}. " \
                          "Available: #{available_keys.inspect}"
        end
      end

      def available_keys
        registry.keys
      end

      private

      def registry
        @registry ||= {}
      end
    end

    # Register the default template bundle (placeholder classes until WP 1a).
    register("default",
      pdf_class: nil,
      verify_partial: nil,
      wallet_data_provider: nil)
  end
end
