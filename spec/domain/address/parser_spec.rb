# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require 'spec_helper'

describe Address::Parser do

  FORMATS = [
    ['Belpstrasse', 'Belpstrasse', nil],
    ['Belpstrasse 1', 'Belpstrasse', '1'],
    ['Belpstrasse, 1', 'Belpstrasse', '1'],
    ['Belpstrasse,1', 'Belpstrasse', '1'],
    ['Belpstrasse 2A', 'Belpstrasse', '2A'],
    ['Belpstrasse 2 A', 'Belpstrasse', '2A'],
    ['Lange Strasse', 'Lange Strasse', nil],
    ['Lange Strasse 2', 'Lange Strasse', '2'],
    ['Lange Strasse 2A', 'Lange Strasse', '2A'],
    ['Lange Strasse 2 A', 'Lange Strasse', '2A'],
    ['Rue du Chemin', 'Rue du Chemin', nil],
    ['Rue du Chemin 2', 'Rue du Chemin', '2'],
    ['Rue du Chemin 2 A', 'Rue du Chemin', '2A'],
    ['Ch. du Rue', 'Ch. du Rue', nil],
    ['Ch. du Rue 2a', 'Ch. du Rue', '2a'],
    ['12 Februar Platz 2', '12 Februar Platz', '2'],
  ].freeze

  def parse(string)
    Address::Parser.new(string)
  end

  FORMATS.each do |string, street, number|
    if number
      it "parses #{string} into street #{street} with number #{number}" do
        subject = parse(string)
        expect(subject.street).to eq street
        expect(subject.number).to eq number
      end
    else
      it "parses #{string} into street #{street} without number" do
        subject = parse(string)
        expect(subject.street).to eq street
        expect(subject.number).to be_nil
      end

    end
  end

end
