# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# encoding:  utf-8

require 'spec_helper'

describe QualificationKindsController, type: :controller do

  class << self
    def it_should_redirect_to_show
      it { is_expected.to redirect_to qualification_kinds_path(returning: true) }
    end
  end

  let(:test_entry) { qualification_kinds(:sl) }
  let(:test_entry_attrs) do
    { label: 'Super Leader',
      description: 'More bla',
      validity: 3,
      reactivateable: 3,
      required_training_days: 5 }
  end

  before { sign_in(people(:top_leader)) }

  include_examples 'crud controller', skip: [%w(show)]

end
