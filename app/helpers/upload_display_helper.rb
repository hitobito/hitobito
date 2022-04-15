# frozen_string_literal: true

#  Copyright (c) 2022-2022, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module UploadDisplayHelper
  # This method provides a facade to serve uploads either from ActiveStorage or
  # CarrierWave
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
  def upload_url(model, name, size: nil, default: model.class.name.underscore, variant: nil) # rubocop:disable Metrics/MethodLength,Metrics/PerceivedComplexity
    return upload_variant(model, name, variant, default: default) if variant.present?

    if model.send(name.to_sym).attached?
      model.send(name.to_sym).yield_self do |pic|
        if size
          # variant passes to mini_magick or vips, I assume mini_magick here
          pic.variant(resize_to_limit: extract_image_dimensions(size))
        else
          pic
        end
      end
    elsif model.respond_to?(:"carrierwave_#{name}") && model.send(:"carrierwave_#{name}")
      model.send(:"carrierwave_#{name}_url")
    else
      upload_default(default)
    end
  end

  # return the filename of the uploaded file
  def upload_name(model, name)
    if model.send(name.to_sym).attached?
      model.send(name.to_sym).filename.to_s
    elsif model.respond_to?(:"carrierwave_#{name}_identifier")
      model.send(:"carrierwave_#{name}_identifier")
    end
  end

  def upload_exists?(model, name)
    return true if model.send(name.to_sym).attached?

    if model.respond_to?(:"carrierwave_#{name}")
      model.send(:"carrierwave_#{name}").present?
    else
      false
    end
  end

  private

  def upload_variant(model, name, variant, default: model.name.underscore)
    if model.send(name.to_sym).attached?
      model.send(name.to_sym).variant(variant.to_sym)
    elsif model.respond_to?(:"carrierwave_#{name}")
      model.send(:"carrierwave_#{name}").send(variant.to_sym).url
    else
      upload_default([default, variant].compact.map(&:to_s).join('_'))
    end
  end

  def upload_default(png_name = 'profil')
    png_name = 'profil' if png_name.include?('..')

    ActionController::Base.helpers.asset_pack_path("media/images/#{png_name}.png")
  end

  def extract_image_dimensions(width_x_height)
    case width_x_height
    when /^\d+x\d+$/ then width_x_height.split('x')
    end
  end
end
