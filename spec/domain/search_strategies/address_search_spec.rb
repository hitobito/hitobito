#  Copyright (c) 2012-2024, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe SearchStrategies::AddressSearch do


  describe '#search_fulltext' do
    let(:user) { Fabricate(:person) }

    it 'for the addresses' do
      [
        {
          :address => addresses(:stossstrasse_bern),
          :search_terms => ['stos', 'stosss', 'stoss bern']
        },
        {
          :address => addresses(:bahnhofstrasse_erlenbach),
          :search_terms => ['bah', 'bahn erlenbach']
        },
        {
          :address => addresses(:seestrasse_erlenbach),
          :search_terms => ['see', 'seestrasse', 'seestrasse erlenbach', 'erlenbach']
        },
        {
          :address => addresses(:rennweg_zuerich),
          :search_terms => ['renn', 'rennweg', 'rennweg zürich', 'zürich']
        },
        {
          :address => addresses(:dorfstrasse_teufen),
          :search_terms => ['dorf', 'dorfstrasse', 'dorfstrasse teufen', 'teufen']
        },
        {
          :address => addresses(:fallenstettenweg_reutlingen),
          :search_terms => ['fall', 'fallenstettenweg', 'fallenstettenweg reutlingen', 'reutlingen']
        },
        {
          :address => addresses(:wiesendangerstrasse_stadel),
          :search_terms => ['wiesen', 'wiesendangerstrasse', 'wiesendangerstrasse stadel', 'stadel']
        },
        {
          :address => addresses(:spitzweg_winterthur),
          :search_terms => ['spitz', 'spitzweg', 'spitzweg winterthur', 'winterthur']
        }
      ].each do |address|
          address[:search_terms].each do |term|
            result = search_class(term).search_fulltext

            expect(result).to include(address[:address]), "'#{address[:address]}' should be found with '#{term}'"
          end
        end
    end
  end

  def search_class(term = nil, page = nil)
    described_class.new(user, term, page)
  end

end