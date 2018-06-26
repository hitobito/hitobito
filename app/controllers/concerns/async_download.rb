module Concerns
  module AsyncDownload

    def with_async_download_cookie(format, name)
      filename = AsyncDownloadFile.create_name(name, current_person.id)
      AsyncDownloadCookie.new(cookies).set(filename, format)
      yield filename
      flash[:notice] = translate(:export_enqueued)
    end
  end
end
