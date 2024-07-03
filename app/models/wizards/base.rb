# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

module Wizards
  class Base
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations

    define_model_callbacks :initialize, :save

    class_attribute :steps, default: []
    class_attribute :shared_partial

    attr_reader :current_ability, :current_step, :params

    def initialize(current_step:, current_ability: nil, **params)
      super(**params.with_indifferent_access.slice(*self.class.attribute_names))
      @current_step = current_step.to_i
      @current_ability = current_ability || Ability.new(Person.new)
      @params = params
    end

    class << self
      # Returns the step name that comes after the given step class or step name.
      # The magic symbol :_start is used to get the first step.
      # Override this method in the subclass if you want to customize the step order (e.g. to have
      # conditional steps or steps that can be skipped based on the user's input)
      def step_after(step_class_or_name)
        return nil if step_class_or_name.nil? || steps.empty?
        return steps.first.step_name if step_class_or_name == :_start

        step_class = if step_class_or_name.is_a?(Class)
                       step_class_or_name
                     else
                       find_step(step_class_or_name)
                     end
        return nil if step_class == steps.last # No step comes after the last step.

        steps[steps.find_index(step_class) + 1].step_name
      end

      # Find the step class by its name.
      def find_step(step_name)
        steps.find do |step|
          step.step_name == step_name.to_s
        end || raise("Step #{step_name} not found")
      end
    end

    def partials = step_instances.map(&:partial)

    # Find the step instance by its index.
    def step_at(index)
      step_instances[index]
    end

    def last_step?
      @current_step == (step_instances.size - 1)
    end

    def first_step?
      @current_step.zero?
    end

    def move_on
      @current_step = next_step if valid?
    end

    # The wizard is valid if its own validations pass and if all steps up to the
    # current step are valid.
    def valid?
      super && step_instances.select do |step_instance|
        validate_step?(step_instance)
      end.all?(&:valid?)
    end

    def save!
      # Only steps up to the current step are validated. So we must prevent saving
      # until the last step is reached.
      raise 'do not call #save! before the last step' unless last_step?
      raise(ActiveRecord::RecordInvalid, self) unless valid?

      true
    end

    def method_missing(name, *args, **kwargs, &block)
      super unless step(name)
      step(name)
    end

    def respond_to_missing?(name, include_private = false)
      step(name) || super
    end

    # Find the step instance by its name.
    def step(step_name)
      step_instances.find { |instance| instance.step_name == step_name.to_s }
    end


    private


    delegate :find_step, :step_after, to: :class, private: true

    # Recursively build the step instances for the wizard using the return value of #step_after.
    def build_step_instances(step_name, instances = [])
      return instances if step_name.nil?

      step_class = find_step(step_name)
      instances << step_class.new(self, **params[step_name] || {})

      next_step = step_after(step_class) || step_after(step_name)
      build_step_instances(next_step, instances)
    end

    def step_instances
      @step_instances ||= build_step_instances(step_after(:_start))
    end

    # Validate all steps up to the current step.
    def validate_step?(step_instance)
      step_index = step_instances.find_index(step_instance)
      @current_step >= step_index
    end

    def next_step
      [@current_step + 1, steps.size - 1].min
    end

    def current_user
      current_ability.user
    end
  end
end
