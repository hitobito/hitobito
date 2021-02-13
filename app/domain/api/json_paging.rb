#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Api::JsonPaging
  def paging_properties(paged_entries)
    next_page = paged_entries.next_page
    prev_page = paged_entries.prev_page

    unsafe_params = params.except(:host).to_unsafe_h

    {
      current_page: paged_entries.current_page,
      total_pages: paged_entries.total_pages,
      next_page_link: next_page ? url_for(unsafe_params.merge(page: next_page)) : nil,
      prev_page_link: prev_page ? url_for(unsafe_params.merge(page: prev_page)) : nil,
    }
  end
end
