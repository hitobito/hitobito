# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe IdnSanitizer do
  it "sanitizes single email" do
    expect(IdnSanitizer.sanitize("foo@exämple.com")).to eq("foo@xn--exmple-cua.com")
  end

  it "sanitizes single email with name" do
    expect(IdnSanitizer.sanitize("Mr. Foo <foo@exämple.com>")).to eq("Mr. Foo <foo@xn--exmple-cua.com>")
  end

  it "keeps regular email" do
    expect(IdnSanitizer.sanitize("foo@example.com")).to eq("foo@example.com")
  end

  it "sanitizes empty email" do
    expect(IdnSanitizer.sanitize(" ")).to eq(" ")
  end

  it "sanitizes regular email with name" do
    expect(IdnSanitizer.sanitize("Mr. Foo <foo@example.com>")).to eq("Mr. Foo <foo@example.com>")
  end

  it "sanitizes multiple emails" do
    expect(IdnSanitizer.sanitize(["foo@exämple.com", "bar@exämple.com"])).to eq(
      ["foo@xn--exmple-cua.com", "bar@xn--exmple-cua.com"])
  end
end
