# encoding: utf-8

#  Copyright (c) 2012-2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AsyncDownloadCookie

  NAME = :async_downloads

  attr_accessor :cookies, :filename, :filetype

  def initialize(cookies, filename, filetype = :txt)
    @cookies  = cookies
    @filename = filename
    @filetype = filetype
  end

  def set
    cookie_value = if async_downloads_cookie.present?
                     async_downloads_cookie << { name: filename, type: filetype }
                   else
                     [name: filename, type: filetype]
                   end

    cookies[NAME] = { value: cookie_value.to_json, expires: 1.day.from_now }
  end

  def remove
    if async_downloads_cookie && async_downloads_cookie.one?
      return cookies.delete NAME
    end

    active_downloads = async_downloads_cookie.collect do |download|
      next if download['name'] == filename
      download
    end.compact

    return unless active_downloads
    cookies[NAME] = { value: active_downloads.to_json, expires: 1.day.from_now }
  end

  private

  def async_downloads_cookie
    cookie_data = cookies[NAME]
    return nil unless cookie_data
    JSON.parse(cookie_data)
  end

end
