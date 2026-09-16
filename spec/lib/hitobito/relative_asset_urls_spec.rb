# frozen_string_literal: true

#  Copyright (c) 2026, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Hitobito::RelativeAssetUrls do
  let(:asset) { Rails.application.assets.load_path.find("application.css") }

  subject(:compiler) { described_class.new(Rails.application.assets) }

  def compile(css) = compiler.compile(asset, css)

  it "normalizes a wagon's relative font reference" do
    expect(compile(%(src: url("../../../fonts/hind-v16-latin-300.woff2");)))
      .to eq %(src: url("hind-v16-latin-300.woff2");)
  end

  it "normalizes an npm package's relative webfont reference" do
    expect(compile("src: url(../webfonts/fa-solid-900.woff2);"))
      .to eq "src: url(fa-solid-900.woff2);"
  end

  it "keeps the path below the asset directory" do
    expect(compile("background: url('../../../images/pdf/scissors.png');"))
      .to eq "background: url('pdf/scissors.png');"
  end

  it "leaves an already flat reference alone" do
    expect(compile(%(background: url("spinner.gif");))).to eq %(background: url("spinner.gif");)
  end

  it "leaves data and absolute urls alone" do
    css = %(background: url("data:image/svg+xml,<svg/>") url("https://example.com/x.png");)
    expect(compile(css)).to eq css
  end

  it "leaves a relative reference to an unregistered directory alone" do
    expect(compile("background: url('../vendor/x.png');")).to eq "background: url('../vendor/x.png');"
  end

  it "is registered before propshaft's own CssAssetUrls" do
    css_compilers = Rails.application.config.assets.compilers
      .select { |mime_type, _| mime_type == "text/css" }.map(&:last)

    expect(css_compilers.index(described_class))
      .to be < css_compilers.index(Propshaft::Compiler::CssAssetUrls)
  end
end
