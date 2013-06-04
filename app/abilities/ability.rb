class Ability

  include CanCan::Ability

  attr_reader :user_context

  class << self
    attr_reader :abilities, :subject_classes

    def register(*ability_classes)
      @subject_classes ||= {}
      ability_classes.each do |ability_class|
        ability_class.subject_classes.each do |subject_class|
          @subject_classes[subject_class] = ability_class
        end

        AbilityDsl::Config.new(ability_class).define
      end
    end

    def add_config(permission, subject_class, actions, condition)
      @abilities ||= {}
      @abilities[subject_class] ||= {}
      @abilities[subject_class][permission] ||= {}
      actions.each do |action|
        @abilities[subject_class][permission][action] = condition
      end
    end
  end


  register EventAbility,
           Event::ApplicationAbility,
           Event::ParticipationAbility,
           Event::RoleAbility,
           GroupAbility,
           MailingListAbility,
           PeopleFilterAbility,
           PersonAbility,
           QualificationAbility,
           RoleAbility,
           SubscriptionAbility,
           VariousAbility


  def initialize(user)
    if user.root?
      can :manage, :all
    else
      @user_context = AbilityDsl::UserContext.new(user)
      define
    end
  end

  def define
    self.class.abilities.each do |subject_class, permissions|
      permissions.each do |permission, actions|
        if user_context.has_permission?(permission)
          actions.each do |action, condition|
            define_ability(permission, subject_class, action, condition)
          end
        end
      end
    end
  end

  def define_ability(permission, subject_class, action, condition)
    if condition == :all
      can action, subject_class
    elsif condition != :none
      can action, subject_class do |subject|
        ability = ability_class(subject_class).new(user_context, subject, permission, action)
        ability.general_conditions && ability.send(condition)
      end
    end
  end

  def ability_class(subject_class)
    self.class.subject_classes[subject_class]
  end
end

