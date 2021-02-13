#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AsyncDownload
  def with_async_download_cookie(format, name, redirection_target: {returning: true})
    filename ||= AsyncDownloadFile.create_name(name, current_person.id)
    Cookies::AsyncDownload.new(cookies).set(name: filename, type: format)
    yield filename
    flash[:notice] = translate(:export_enqueued)
    redirect_to redirection_target
  end
end
