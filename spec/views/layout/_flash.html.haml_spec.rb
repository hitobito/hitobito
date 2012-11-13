# encoding: UTF-8
require 'spec_helper'
describe 'layouts/_flash.html.haml' do
  let(:dom) { Capybara::Node::Simple.new(rendered) }
  subject { dom.find('p') } 
  before do
    view.stub(level: :info)
    controller.flash[:info] = info
    render
  end

  context "splits array into lines" do
    let(:info) { ["foo", "bar"] }
    its("native.to_xml") { should =~ %r{<br/>} } 
    its(:text) { should eq "foo\nbar" } 
  end

  context "does not escape html" do
    let(:info) { "<i>foo</i>" } 
    its("native.to_xml") { should =~ %r{<i>foo</i>} } 
    its(:text) { should eq "foo" } 
  end


end

