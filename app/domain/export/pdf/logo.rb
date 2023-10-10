# frozen_string_literal: true

#  Copyright (c) 2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export
  module Pdf
    # Render a logo at the current curser position with the given width and height.
    # The logo can be aligned to the left or right side of the page. The logo can be
    # padded with a given amount of pixels.
    class Logo < Section
      VALID_POSITIONS = [:left, :right].freeze

      attr_reader :pdf, :attachment, :image_width, :image_height, :position, :options,
                  :padding_top, :padding_right, :padding_bottom, :padding_left

      # @param [Prawn::Document] pdf
      # @param [ActiveStorage::Attachment] attachment
      # @param [Integer] image_width
      # @param [Integer] image_height
      # @param [Symbol] position one of :left or :right
      # @param [Hash] options passed to Prawn::Document#image
      def initialize(pdf, attachment, image_width:, image_height:, position:, **options) # rubocop:disable Metrics/ParameterLists
        super(pdf, attachment, options)
        @attachment = attachment
        @image_width = image_width
        @image_height = image_height
        @position = position&.to_sym
        @padding_left = @padding_right = @padding_top = @padding_bottom = 0.mm

        unless VALID_POSITIONS.include?(position)
          raise ArgumentError,
                "position is #{position.inspect} must be one of #{VALID_POSITIONS.inspect}"
        end
      end

      # Set the padding in all directions. The padding is added to the width and height.
      #
      # @param [Integer] top
      # @param [Integer] right
      # @param [Integer] bottom
      # @param [Integer] left
      #
      # @return [self]
      def with_padding(top: 0, right: 0, bottom: 0, left: 0)
        @padding_top = top
        @padding_right = right
        @padding_bottom = bottom
        @padding_left = left
        self
      end

      def render # rubocop:disable Metrics/AbcSize
        return unless attachment&.attached?

        # Create a bounding box at the upper left corner of the logo including the padding.
        padded_left = position == :left ? 0 : bounds.width - width
        bounding_box([padded_left, cursor], width: width, height: height) do

          # Create a bounding box at the upper left corner of the logo without the padding.
          bounding_box([padding_left, cursor - padding_top], width: image_width,
                                                             height: image_height) do
            attachment.blob.open do |logo_file|
              image(logo_file, logo_options(image_width, image_height, position: position))
            end
          end
        end
      end

      # @return [Integer] the width of the logo including the padding
      def width
        image_width + padding_left + padding_right
      end

      # @return [Integer] the height of the logo including the padding
      def height
        image_height + padding_top + padding_bottom
      end

      private

      def logo_options(image_width, image_height, **opts)
        if logo_exceeds_box?(image_width, image_height)
          opts[:fit] = [image_width, image_height]
        end
        opts
      end

      def logo_exceeds_box?(box_width, box_height)
        width, height = logo_dimensions
        width > box_width || height > box_height
      end

      def logo_dimensions
        attachment.analyze unless attachment.analyzed?
        metadata = attachment.blob.metadata

        [metadata[:width], metadata[:height]]
      end
    end
  end
end
