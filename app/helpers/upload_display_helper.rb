# frozen_string_literal: true

#  Copyright (c) 2022-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module UploadDisplayHelper
  # This method provides a facade to serve uploads
  #
  # Usage:
  #
  # upload_url(person, :picture)
  # upload_url(person, :picture, size: '72x72')
  # upload_url(person, :picture, size: '72x72')
  # upload_url(person, :picture, variant: :thumb)
  # upload_url(person, :picture, variant: :thumb, default: 'profil')
  #
  # could be
  #
  # person.picture or
  # person.picture.variant(resize_to_limit: [72, 72]) or
  # person.picture.variant(:thumb)
  #
  # This helper returns a suitable first argument for image_tag (the image location),
  # but also for the second arg of link_to (the target).
  def upload_url(model, name, size: nil, default: model.class.name.underscore, variant: nil) # rubocop:disable Metrics/MethodLength
    return upload_variant(model, name, variant, default: default) if variant.present?

    if upload_exists?(model, name)
      model.send(name.to_sym).then do |pic|
        if size
          # variant passes to mini_magick or vips, I assume mini_magick here
          pic.variant(resize_to_limit: extract_image_dimensions(size))
        else
          pic
        end
      end
    else
      upload_default(model, name, default)
    end
  end

  # return the filename of the uploaded file
  def upload_name(model, name)
    model.send(name.to_sym).filename.to_s if upload_exists?(model, name)
  end

  def upload_exists?(model, name)
    model.send(name.to_sym).attached?
  end

  private

  def upload_variant(model, name, variant, default: model.class.name.underscore)
    if upload_exists?(model, name)
      model.send(name.to_sym).variant(variant.to_sym)
    else
      default_variant = [default, variant].compact.map(&:to_s).join('_')
      name_variant = [name, variant].compact.map(&:to_s).join('_')

      upload_default(model, name_variant, default_variant)
    end
  end

  def upload_default(model, name, png_name = 'profil')
    filename = if model.respond_to?(:"#{name}_default")
                 model.send(:"#{name}_default")
               else
                 "#{png_name}.png"
               end

    ActionController::Base.helpers.asset_pack_path("media/images/#{filename}")
  end

  def extract_image_dimensions(width_x_height)
    case width_x_height
    when /^\d+x\d+$/ then width_x_height.split('x')
    end
  end
end
