# encoding: utf-8
require_relative 'event/application_decorator.rb'
class PersonDecorator < ApplicationDecorator
  decorates :person

  include ContactableDecorator

  def as_typeahead
    {id: id, name: full_label}
  end

  def full_name
    model.to_s.split('/').first
  end

  def full_label
    label = to_s
    label << ", #{town}" if town?
    if company?
      name = "#{first_name} #{last_name}".strip
      label << " (#{name})" if name.present?
    else
      label << " (#{birthday.year})" if birthday
    end
    label
  end
  
  # render a list of all roles
  # if a group is given, only render the roles of this group
  def roles_short(group = nil)
    functions_short(roles.to_a, :group, group)
  end
  
  def pending_applications
    Event::ApplicationDecorator.decorate(event_applications.pending)
  end

  def upcoming_events
    EventDecorator.decorate(events.upcoming)
  end
  
  private
  
  def functions_short(functions, scope_method, scope = nil)
    functions.select!{|r| r.send("#{scope_method}_id") == scope.id } if scope
    h.safe_join(functions) do |f|
      content_tag(:p, function_short(f, scope_method, scope))
    end
  end
  
  def function_short(function, scope_method, scope = nil)
    html = [function.to_s]
    html << h.muted(function.send(scope_method).to_s) if scope.nil?
    h.safe_join(html, ' ')
  end
  
  
end
