# encoding: utf-8

#  Copyright (c) 2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe LabelFormat do

  it 'nullifies people last_label_format_id on destroy' do
    f = Fabricate(:label_format)
    p = Person.first
    p.update!(last_label_format: f)
    f.destroy
    expect(p.reload.last_label_format_id).to be_nil
  end

end