# == Schema Information
#
# Table name: custom_contents
#
#  id                    :integer          not null, primary key
#  key                   :string(255)      not null
#  label                 :string(255)      not null
#  subject               :string(255)
#  body                  :text
#  placeholders_required :string(255)
#  placeholders_optional :string(255)
#

require 'spec_helper'

describe CustomContent do
  
end
