require 'spec_helper'

describe AutoLinkHelper do
  
  it "links www addresses" do
    auto_link('www.puzzle.ch').should == '<a href="http://www.puzzle.ch" target="_blank">www.puzzle.ch</a>'
  end
  
  it "links http addresses" do
    auto_link('http://puzzle.ch').should == '<a href="http://puzzle.ch" target="_blank">http://puzzle.ch</a>'
  end
  
  it "links ftps addresses" do
    auto_link('ftps://puzzle.ch').should == '<a href="ftps://puzzle.ch" target="_blank">ftps://puzzle.ch</a>'
  end
  
  it "links email addresses" do
    auto_link('admin@puzzle.ch').should == '<a href="mailto:admin@puzzle.ch">admin@puzzle.ch</a>'
  end
  
  it "does not link addresses without www" do
    auto_link('abc.puzzle.ch').should == 'abc.puzzle.ch'
  end
  
  it "does not link www." do
    auto_link('www.').should == 'www.'
  end
  
  it "does not link anything with @" do
    auto_link('@puzzle.ch').should == '@puzzle.ch'
    auto_link('a$#!@puzzle.ch').should == 'a$#!@puzzle.ch'
  end
  
end
