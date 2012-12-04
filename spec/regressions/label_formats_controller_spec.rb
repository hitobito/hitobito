# encoding:  utf-8

require 'spec_helper'

describe Event::LabelFormatsController, type: :controller do

  class << self
    def it_should_redirect_to_show
      it { should redirect_to label_formats_path } 
    end
  end

  let(:test_entry) { label_formats(:standard) }
  let(:test_entry_attrs) { { name: 'foo', 
                             page_size: 'A4',
                             landscape: true,
                             font_size: 12.0,
                             width: 99.0,
                             height: 99.0,
                             count_horizontal: 22,
                             count_vertical: 22,
                             padding_top: 2.0,
                             padding_left: 2.0
                              } }

  before { sign_in(people(:top_leader)) } 

  include_examples 'crud controller', skip: [%w(show)]

end
