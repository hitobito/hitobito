# encoding: utf-8
require 'spec_helper'


describe "shared/_dropdown_button.html.haml" do

  let(:group) { groups(:top_layer) }
  let(:subject) { Capybara::Node::Simple.new(@rendered) }

  before { view.stub(entry: GroupDecorator.new(group), can?: false) }


  it "renders dropdown" do
    render partial: 'shared/dropdown_button',
           locals: {label: 'Neue Gruppe erstellen',
                    items: [Dropdown::Item.new('Group::TopGroup', '#'),
                            Dropdown::Item.new('Group::BottomLayer', '#')],
                    icon_name: nil,
                    main_link: nil}

    should have_content "Neue Gruppe erstellen"
    should have_selector 'ul.dropdown-menu'
    should have_selector 'a' do |tag|
      tag.should have_content 'Group::TopGroup'
    end
    should have_selector 'a' do |tag|
      tag.should have_content 'Group::BottomLayer'
    end
  end


end
