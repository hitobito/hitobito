# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Contains assertions for testing common crud controller use cases.
# See crud_controller_examples for use cases.
module CrudControllerTestHelper
  extend ActiveSupport::Concern

  # Performs a request based on the metadata of the action example under test.
  def perform_request
    m = example.metadata
    example_params = respond_to?(:params) ? send(:params) : {}
    params = scope_params.merge(format: m[:format])
    params.merge!(id: test_entry.id) if m[:id]
    params.merge!(example_params)

    sign_in(user)
    if m[:method] == :get && m[:format] == :js
      xhr(:get, m[:action], params)
    else
      send(m[:method], m[:action], params)
    end
  end

  def perform_combined_request
    if stack = example.metadata[:combine]
      @@current_stack ||= nil
      if stack == @@current_stack && described_class == @@current_controller.class
        @response = @@current_response
        @_templates = @@current_templates
        @controller = @@current_controller
        @request = @@current_request
        return
      end

      perform_request

      @@current_stack = stack
      @@current_response = @response
      @@current_request = @request
      @@current_controller = @controller
      @@current_templates = @_templates
    else
      perform_request
    end
  end

  # The params defining the nesting of the test entry.
  def scope_params
    params = {}
    # for nested controllers, add parent ids to each request
    Array(controller.nesting).reverse.inject(test_entry) do |parent, p|
      if p.is_a?(Class) && p < ActiveRecord::Base
        assoc = p.name.underscore
        params["#{assoc}_id"] = parent.send(:"#{assoc}_id")
        parent.send(assoc)
      else
        parent
      end
    end
    params
  end

  def test_attrs
    action = example.metadata[:action]
    action_specific_attr_name = "#{action}_entry_attrs".to_sym
    if respond_to?(action_specific_attr_name)
      send(action_specific_attr_name)
    else
      action = { new: :create, edit: :update }[action.to_sym] || action
      respond_to?(action_specific_attr_name) ? send(action_specific_attr_name) : test_entry_attrs
    end
  end


  def deep_attributes(attrs, entry)
    actual = {}
    attrs.keys.each do |key|
      if key.to_s.ends_with?('_attributes')
        assoc = entry.send(key.to_s[/(.+)_attributes/, 1])
        actual[key] = if assoc.respond_to?(:each)
          assoc.collect { |a| deep_attributes(attrs[key].first, a) }
        else
          deep_attributes(attrs[key], assoc)
        end
      else
        actual[key] = entry.send(key)
      end
    end
    actual
  end

  module ClassMethods

    # Describe a certain action and provide some usefull metadata.
    # Tests whether this action is configured to be skipped.
    def describe_action(method, action, metadata = {}, &block)
      describe("#{method.to_s.upcase} #{action}",
               { if: described_class.instance_methods.collect(&:to_s).include?(action.to_s),
                 method: method,
                 action: action }.
               merge(metadata),
               &block)
    end

    def skip?(options, *contexts)
      options ||= {}
      contexts = Array(contexts).flatten
      skips = Array(options[:skip])
      skips = [skips] if skips.blank? || !skips.first.is_a?(Array)

      # puts "#{skips}, #{contexts} == #{skips.flatten.present? && skips.any? { |skip| skip == contexts.take(skip.size) }} "
      skips.flatten.present? && skips.any? { |skip| skip == contexts.take(skip.size) }
    end

    # Test the response status, default 200.
    def it_should_respond(status = 200)
      its(:status) { should == status }
    end

    # Test that entries are assigned.
    def it_should_assign_entries
      it 'should assign entries' do
        entries.should be_present
      end
    end

    # Test that entry is assigned.
    def it_should_assign_entry
      it 'should assign entry' do
        entry.should == test_entry
      end
    end

    # Test that the given template or the main template of the action under test is rendered.
    def it_should_render(template = nil)
      it { should render_template(template || example.metadata[:action]) }
    end

    # Test that test_entry_attrs are set on entry.
    def it_should_set_attrs
      it 'should set params as entry attributes' do
        attrs = test_attrs
        deep_attributes(attrs, entry).should == attrs
      end
    end

    # Test that the response redirects to the index action.
    def it_should_redirect_to_index
      it { should redirect_to scope_params.merge(action: 'index', returning: true) }
    end

    # Test that the response redirects to the show action of the current entry.
    def it_should_redirect_to_show
      it { should redirect_to scope_params.merge(action: 'show', id: entry.id) }
    end

    # Test that the given flash type is present.
    def it_should_have_flash(type, message = nil)
      context 'flash' do
        subject { flash }

        its([type]) do
          should(message ? match(message) : be_present)
        end
      end
    end

    # Test that not flash of the given type is present.
    def it_should_not_have_flash(type)
      context 'flash' do
        subject { flash }
        its([type]) { should be_blank }
      end
    end

    # Test that the current entry is persistend and valid, or not.
    def it_should_persist_entry(bool = true)
      context 'entry' do
        subject { entry }

        if bool
          it { should be_persisted }
          it { entry.valid?; should(be_valid, entry.errors.full_messages.join("\n")) }
        else
          it { should_not be_persisted }
        end
      end
    end
  end

end
