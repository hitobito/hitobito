require 'spec_helper_request'

describe "load environment", js: true do
  it "loops until success" do
    begin
      visit '/'
    rescue => ex
      print ex.message
      puts ex.backtrace
      retry
    end
  end
end