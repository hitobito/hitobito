# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ContactableHelper
  def info_field_set_tag(legend = nil, options = {}, &block)
    if entry.is_a?(Group)
      opts = { class: 'info' }
      opts.merge!(entry.contact ? { style: 'display: none' } : {})
      field_set_tag(legend, options.merge(opts), &block)
    else
      field_set_tag(legend, options, &block)
    end
  end
end
