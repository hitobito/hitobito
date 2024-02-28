# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe MountedAttr do
  let(:string_attrs) do
    [
      :string, :string_nullable, :string_non_nullable,
      :string_with_default, :string_with_default_nullable, :string_with_default_non_nullable,
      :string_with_default_empty, :string_with_default_emtpy_nullable, :string_with_default_empty_non_nullable,
      :string_with_default_null, :string_with_default_null_nullable, :string_with_default_null_non_nullable
    ]
  end

  let(:integer_attrs) do
    [
      :integer, :integer_nullable, :integer_non_nullable,
      :integer_with_default, :integer_with_default_nullable, :integer_with_default_non_nullable,
      :integer_with_default_zero, :integer_with_default_zero_nullable, :integer_with_default_zero_non_nullable,
      :integer_with_default_null, :integer_with_default_null_nullable, :integer_with_default_null_non_nullable
    ]
  end

  let(:boolean_attrs) do
    [
      :boolean, :boolean_nullable, :boolean_non_nullable,
      :boolean_with_default_false, :boolean_with_default_false_nullable, :boolean_with_default_false_non_nullable,
      :boolean_with_default_true, :boolean_with_default_true_nullable, :boolean_with_default_true_non_nullable,
      :boolean_with_default_null, :boolean_with_default_null_nullable, :boolean_with_default_null_non_nullable
    ]
  end

  let!(:entry) do
    Group::MountedAttrsGroup.new(name: 'MountedAttrsTest', parent: groups(:bottom_layer_one))
  end

  context 'getter' do
    context 'string attribute' do
      it 'returns nil for unset attributes without default' do
        [:string, :string_nullable, :string_non_nullable].each do |attr|
          expect(entry.send(attr)).to be_nil,
                                      "expected #{attr} to be nil but was #{entry.send(attr).inspect}"
        end
      end

      it 'returns default for unset attributes with default' do
        [:string_with_default, :string_with_default_nullable,
         :string_with_default_non_nullable].each do |attr|
          expect(entry.send(attr)).to eq('default'),
                                      "expected #{attr} to be 'default' but was #{entry.send(attr).inspect}"
        end

        [:string_with_default_empty, :string_with_default_emtpy_nullable,
         :string_with_default_empty_non_nullable].each do |attr|
          expect(entry.send(attr)).to eq(''),
                                      "expected #{attr} to be '' but was #{entry.send(attr).inspect}"
        end

        [:string_with_default_null, :string_with_default_null_nullable,
         :string_with_default_null_non_nullable].each do |attr|
          expect(entry.send(attr)).to be_nil,
                                      "expected #{attr} to be nil but was #{entry.send(attr).inspect}"
        end
      end
    end

    context 'integer attribute' do
      it 'returns nil for unset attributes without default' do
        [:integer, :integer_nullable, :integer_non_nullable].each do |attr|
          expect(entry.send(attr)).to be_nil,
                                      "expected #{attr} to be nil but was #{entry.send(attr).inspect}"
        end
      end

      it 'returns default for unset attributes with default' do
        [:integer_with_default, :integer_with_default_nullable,
         :integer_with_default_non_nullable].each do |attr|
          expect(entry.send(attr)).to eq(42),
                                      "expected #{attr} to be 42 but was #{entry.send(attr).inspect}"
        end

        [:integer_with_default_zero, :integer_with_default_zero_nullable,
         :integer_with_default_zero_non_nullable].each do |attr|
          expect(entry.send(attr)).to eq(0),
                                      "expected #{attr} to be 0 but was #{entry.send(attr).inspect}"
        end

        [:integer_with_default_null, :integer_with_default_null_nullable,
         :integer_with_default_null_non_nullable].each do |attr|
          expect(entry.send(attr)).to be_nil,
                                      "expected #{attr} to be nil but was #{entry.send(attr).inspect}"
        end
      end
    end

    context 'boolean attribute' do
      it 'returns nil for unset attributes without default' do
        [:boolean, :boolean_nullable, :boolean_non_nullable].each do |attr|
          expect(entry.send(attr)).to be_nil,
                                      "expected #{attr} to be nil but was #{entry.send(attr).inspect}"
        end
      end

      it 'returns default for unset attributes with default' do
        [:boolean_with_default_false, :boolean_with_default_false_nullable,
         :boolean_with_default_false_non_nullable].each do |attr|
          expect(entry.send(attr)).to eq(false),
                                      "expected #{attr} to be false but was #{entry.send(attr).inspect}"
        end

        [:boolean_with_default_true, :boolean_with_default_true_nullable,
         :boolean_with_default_true_non_nullable].each do |attr|
          expect(entry.send(attr)).to eq(true),
                                      "expected #{attr} to be true but was #{entry.send(attr).inspect}"
        end

        [:boolean_with_default_null, :boolean_with_default_null_nullable,
         :boolean_with_default_null_non_nullable].each do |attr|
          expect(entry.send(attr)).to be_nil,
                                      "expected #{attr} to be nil but was #{entry.send(attr).inspect}"
        end
      end
    end
  end

  context 'setter' do
    context 'string attribute' do
      it 'sets value' do
        string_attrs.each do |attr|
          entry.send("#{attr}=", 'string')
          expect(entry.send(attr)).to eq('string'),
                                      "expected #{attr} to be 'string' but was #{entry.send(attr).inspect}"
        end
      end

      it 'sets nil for attribute without default' do
        [:string, :string_nullable, :string_non_nullable].each do |attr|
          entry.send("#{attr}=", nil)
          expect(entry.send(attr)).to be_nil,
                                      "expected #{attr} to be nil but was #{entry.send(attr).inspect}"
        end
      end

      it 'does not set nil for attribute with default' do
        [
          :string_with_default, :string_with_default_nullable, :string_with_default_non_nullable,
          :string_with_default_empty, :string_with_default_emtpy_nullable, :string_with_default_empty_non_nullable
        ].each do |attr|
          entry.send("#{attr}=", nil)
          expect(entry.send(attr)).not_to be_nil, "expected #{attr} not to be nil but it was"
        end
      end

      it 'sets empty string for attribute without default' do
        [:string, :string_nullable, :string_non_nullable].each do |attr|
          entry.send("#{attr}=", '')
          expect(entry.send(attr)).to eq(''),
                                      "expected #{attr} to be '' but was #{entry.send(attr).inspect}"
        end
      end

      it 'does not set empty string for attribute with default' do
        [
          :string_with_default, :string_with_default_nullable, :string_with_default_non_nullable,
          :string_with_default_empty, :string_with_default_emtpy_nullable, :string_with_default_empty_non_nullable
        ].each do |attr|
          entry.send("#{attr}=", '')
          expect(entry.send(attr)).not_to be_nil, "expected #{attr} not to be '' but it was"
        end
      end
    end

    context 'integer attribute' do
      it 'sets value' do
        integer_attrs.each do |attr|
          entry.send("#{attr}=", 43)
          expect(entry.send(attr)).to eq(43),
                                      "expected #{attr} to be 43 but was #{entry.send(attr).inspect}"
        end
      end

      it 'sets nil for attribute without default' do
        [:integer, :integer_nullable, :integer_non_nullable].each do |attr|
          entry.send("#{attr}=", nil)
          expect(entry.send(attr)).to be_nil,
                                      "expected #{attr} to be nil but was #{entry.send(attr).inspect}"
        end
      end

      it 'does not set nil for attribute with default' do
        [
          :integer_with_default, :integer_with_default_nullable, :integer_with_default_non_nullable,
          :integer_with_default_zero, :integer_with_default_zero_nullable, :integer_with_default_zero_non_nullable
        ].each do |attr|
          entry.send("#{attr}=", nil)
          expect(entry.send(attr)).not_to be_nil, "expected #{attr} not to be nil but it was"
        end
      end

      it 'sets 0 for attribute without default' do
        [:integer, :integer_nullable, :integer_non_nullable].each do |attr|
          entry.send("#{attr}=", 0)
          expect(entry.send(attr)).to eq(0),
                                      "expected #{attr} to be 0 but was #{entry.send(attr).inspect}"
        end
      end

      it 'does not set 0 for attribute with default' do
        [
          :integer_with_default, :integer_with_default_nullable, :integer_with_default_non_nullable
        ].each do |attr|
          entry.send("#{attr}=", 0)
          expect(entry.send(attr)).not_to be_nil, "expected #{attr} not to be 0 but it was"
        end
      end
    end

    context 'boolean attribute' do
      it 'sets true' do
        boolean_attrs.each do |attr|
          entry.send("#{attr}=", true)
          expect(entry.send(attr)).to eq(true),
                                      "expected #{attr} to be true but was #{entry.send(attr).inspect}"
        end
      end

      it 'sets false' do
        boolean_attrs.each do |attr|
          entry.send("#{attr}=", false)
          expect(entry.send(attr)).to eq(false),
                                      "expected #{attr} to be false but was #{entry.send(attr).inspect}"
        end
      end

      it 'casts "1" to true' do
        boolean_attrs.each do |attr|
          entry.send("#{attr}=", "1")
          expect(entry.send(attr)).to eq(true),
                                      "expected #{attr} to be true but was #{entry.send(attr).inspect}"
        end
      end

      it 'casts "0" to false' do
        boolean_attrs.each do |attr|
          entry.send("#{attr}=", "0")
          expect(entry.send(attr)).to eq(false),
                                      "expected #{attr} to be false but was #{entry.send(attr).inspect}"
        end
      end

      it 'sets nil for attribute without default' do
        [:boolean, :boolean_nullable, :boolean_non_nullable].each do |attr|
          entry.send("#{attr}=", nil)
          expect(entry.send(attr)).to be_nil,
                                      "expected #{attr} to be nil but was #{entry.send(attr).inspect}"
        end
      end

      it 'does not set nil for attribute with default' do
        [
          :boolean_with_default_false, :boolean_with_default_false_nullable, :boolean_with_default_false_non_nullable,
          :boolean_with_default_true, :boolean_with_default_true_nullable, :boolean_with_default_true_non_nullable
        ].each do |attr|
          entry.send("#{attr}=", nil)
          expect(entry.send(attr)).not_to be_nil, "expected #{attr} not to be nil but it was"
        end
      end
    end
  end

  context 'validations' do
    def validates_presence(value, attrs, nullable: true)
      attrs.each { |attr| entry.send("#{attr}=", value) }
      entry.validate

      attrs.each do |attr|
        if nullable
          expect(entry.errors[attr]).to be_empty,
                                        "expected #{attr} to be nullable but was not"
        else
          expect(entry.errors[attr]).to eq(['muss ausgefüllt werden']),
                                        "expected #{attr} to be non-nullable but was not: #{entry.errors[attr].inspect}"
        end
      end
    end

    def ignores_absence(value, attrs)
      validates_presence(value, attrs, nullable: false)
    end

    context 'string attribute' do
      it 'allows null for nullable attributes' do
        validates_presence(nil, [
                             :string,
                             :string_nullable,
                             :string_with_default,
                             :string_with_default_nullable,
                             :string_with_default_empty,
                             :string_with_default_emtpy_nullable,
                             :string_with_default_null,
                             :string_with_default_null_nullable
                           ])
      end

      it 'allows emtpy string for nullable attributes' do
        validates_presence('', [
                             :string,
                             :string_nullable,
                             :string_with_default,
                             :string_with_default_nullable,
                             :string_with_default_empty,
                             :string_with_default_emtpy_nullable,
                             :string_with_default_null,
                             :string_with_default_null_nullable
                           ])
      end

      it 'denies null for non-nullable attributes' do
        ignores_absence(nil, [
                          :string_non_nullable,
                          :string_with_default_empty_non_nullable,
                          :string_with_default_null_non_nullable
                        ])
      end

      it 'denies empty string for non-nullable attributes' do
        ignores_absence('', [
                          :string_non_nullable,
                          :string_with_default_empty_non_nullable,
                          :string_with_default_null_non_nullable
                        ])
      end
    end

    context 'integer attribute' do
      it 'allows null for nullable attributes' do
        validates_presence(nil, [
                             :integer,
                             :integer_nullable,
                             :integer_with_default,
                             :integer_with_default_nullable,
                             :integer_with_default_zero,
                             :integer_with_default_zero_nullable,
                             :integer_with_default_null,
                             :integer_with_default_null_nullable
                           ])
      end

      it 'denies null for non-nullable attributes without default' do
        ignores_absence(nil, [
                          :integer_non_nullable
                        ])
      end
    end

    context 'boolean attribute' do
      it 'allows null for nullable attributes' do
        validates_presence(nil, [
                             :boolean,
                             :boolean_nullable,
                             :boolean_with_default_false,
                             :boolean_with_default_false_nullable,
                             :boolean_with_default_true,
                             :boolean_with_default_true_nullable,
                             :boolean_with_default_null,
                             :boolean_with_default_null_nullable
                           ])
      end

      it 'denies null for non-nullable attributes without default' do
        ignores_absence(nil, [
                          :boolean_non_nullable
                        ])
      end
    end
  end

  context 'persistance' do
    def expect_persisted(value, attrs)
      # set all attributes to some valid value so we can save the record
      string_attrs.each { |attr| entry.send("#{attr}=", 'some-valid-string') }
      integer_attrs.each { |attr| entry.send("#{attr}=", 12_345) }
      boolean_attrs.each { |attr| entry.send("#{attr}=", true) }
      entry.save!

      # set the provided value for the specified attributes
      attrs.each { |attr| entry.send("#{attr}=", value) }
      entry.save!
      entry.reload

      attrs.each do |attr|
        expect(entry.send(attr)).to eq(value),
                                    "expected #{attr} to be #{value.inspect} but was #{entry.send(attr).inspect}"
      end
    end

    context 'string attribute' do
      it 'persists value' do
        expect_persisted('string', string_attrs)
      end

      it 'persists empty string for nullable attributes without default' do
        attrs = [:string, :string_nullable]

        expect_persisted('', attrs)
      end

      it 'persists nil for nullable attributes without default' do
        attrs = [:string, :string_nullable]

        expect_persisted(nil, attrs)
      end
    end

    context 'integer attribute' do
      it 'persists value' do
        expect_persisted(42, integer_attrs)
      end

      it 'persists 0 for nullable attributes without default' do
        attrs = [:integer, :integer_nullable]

        expect_persisted(0, attrs)
      end

      it 'persists nil for nullable attributes without default' do
        attrs = [:integer, :integer_nullable]

        expect_persisted(nil, attrs)
      end
    end

    context 'boolean attribute' do
      it 'persists true' do
        expect_persisted(true, boolean_attrs)
      end

      it 'persists false' do
        expect_persisted(false, boolean_attrs)
      end

      it 'persists nil for nullable attributes without default' do
        attrs = [:boolean, :boolean_nullable]

        expect_persisted(nil, attrs)
      end
    end
  end

  describe 'type lookup method' do
    [:string, :integer, :boolean].each do |type|
      it "returns the type for #{type} attributes" do
        expect(entry.send("#{type}_type")).to eq(type)
      end
    end
  end

  describe '#save_mounted_attributes' do

    def test_entry(&block)
      # create an entry for a custom group that has mounted attributes defined on the fly
      stub_const('TestGroup', Class.new(Group) do
        self.layer = true
        instance_eval(&block)
      end).new(name: 'TestGroup').tap(&:save!)
    end

    it 'does not persist new records with default value' do
      entry = test_entry { mounted_attr :test, :string, default: :hello_world }
      expect { entry.save_mounted_attributes }.not_to change { MountedAttribute.count }
    end

    it 'does not persist new records with default value' do
      entry = test_entry { mounted_attr :test, :string, default: :hello_world }
      entry.test = 'non-default value'
      expect { entry.save_mounted_attributes }.to change { MountedAttribute.count }
    end

    it 'does update existing records with default value' do
      entry = test_entry { mounted_attr :test, :string, default: :hello_world }
      entry.update!(test: 'non-default value')
      expect(entry.mounted_attributes.find_by(key: :test).value).to eq 'non-default value'

      expect {
        entry.test = 'hello_world'
        entry.save_mounted_attributes
      }.to not_change { MountedAttribute.count }.
        and change { entry.mounted_attributes.find_by(key: :test).value }.
        from('non-default value').to('hello_world')
    end

  end
end
