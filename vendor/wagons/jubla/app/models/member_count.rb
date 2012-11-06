class MemberCount < ActiveRecord::Base
  
  attr_accessible :leader_f, :leader_m, :child_f, :child_m
  
  belongs_to :flock, class_name: 'Group::Flock'
  belongs_to :state, class_name: 'Group::State'
  
end