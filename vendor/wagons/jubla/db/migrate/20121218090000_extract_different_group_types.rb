class ExtractDifferentGroupTypes < ActiveRecord::Migration
  def up
    # work groups
    groups('Group::WorkGroup', 'Group::Federation').update_all(type: 'Group::FederalWorkGroup')
    roles('Group::WorkGroup::Leader', 'Group::Federation').update_all(type: 'Group::FederalWorkGroup::Leader')
    roles('Group::WorkGroup::Member', 'Group::Federation').update_all(type: 'Group::FederalWorkGroup::Member')
    
    groups('Group::WorkGroup', 'Group::State').update_all(type: 'Group::StateWorkGroup')
    roles('Group::WorkGroup::Leader', 'Group::State').update_all(type: 'Group::StateWorkGroup::Leader')
    roles('Group::WorkGroup::Member', 'Group::State').update_all(type: 'Group::StateWorkGroup::Member')
    
    groups('Group::WorkGroup', 'Group::Region').update_all(type: 'Group::RegionalWorkGroup')
    roles('Group::WorkGroup::Leader', 'Group::Region').update_all(type: 'Group::RegionalWorkGroup::Leader')
    roles('Group::WorkGroup::Member', 'Group::Region').update_all(type: 'Group::RegionalWorkGroup::Member')
    
    
    # professional groups
    groups('Group::ProfessionalGroup', 'Group::Federation').update_all(type: 'Group::FederalProfessionalGroup')
    roles('Group::ProfessionalGroup::Leader', 'Group::Federation').update_all(type: 'Group::FederalProfessionalGroup::Leader')
    roles('Group::ProfessionalGroup::Member', 'Group::Federation').update_all(type: 'Group::FederalProfessionalGroup::Member')
    
    groups('Group::ProfessionalGroup', 'Group::State').update_all(type: 'Group::StateProfessionalGroup')
    roles('Group::ProfessionalGroup::Leader', 'Group::State').update_all(type: 'Group::StateProfessionalGroup::Leader')
    roles('Group::ProfessionalGroup::Member', 'Group::State').update_all(type: 'Group::StateProfessionalGroup::Member')
    
    groups('Group::ProfessionalGroup', 'Group::Region').update_all(type: 'Group::RegionalProfessionalGroup')
    roles('Group::ProfessionalGroup::Leader', 'Group::Region').update_all(type: 'Group::RegionalProfessionalGroup::Leader')
    roles('Group::ProfessionalGroup::Member', 'Group::Region').update_all(type: 'Group::RegionalProfessionalGroup::Member')
    
    
    # coaches
    roles('Jubla::Role::Coach', 'Group::State').update_all(type: 'Group::State::Coach')
    roles('Jubla::Role::Coach', 'Group::Region').update_all(type: 'Group::Region::Coach')
    
    
    # filters
    PeopleFilter::RoleType.where(role_type: %w(Group::WorkGroup::Leader 
                                               Group::WorkGroup::Member 
                                               Group::ProfessionalGroup::Leader 
                                               Group::ProfessionalGroup::Member 
                                               Jubla::Role::Coach)).
                           destroy_all
  end

  def down
    # professional groups
    Group.with_deleted.
          where(type: %w(Group::FederalProfessionalGroup 
                         Group::StateProfessionalGroup 
                         Group::RegionalProfessionalGroup)).
          update_all(type: 'Group::ProfessionalGroup')
          
    Role.with_deleted.
         where(type: %w(Group::FederalProfessionalGroup::Leader 
                        Group::StateProfessionalGroup::Leader 
                        Group::RegionalProfessionalGroup::Leader)).
         update_all(type: 'Group::ProfessionalGroup::Leader')
         
    Role.with_deleted.
         where(type: %w(Group::FederalProfessionalGroup::Member 
                        Group::StateProfessionalGroup::Member 
                        Group::RegionalProfessionalGroup::Member)).
         update_all(type: 'Group::ProfessionalGroup::Member')
    
    
    # work groups
    Group.with_deleted.
          where(type: %w(Group::FederalWorkGroup 
                         Group::StateWorkGroup 
                         Group::RegionalWorkGroup)).
          update_all(type: 'Group::WorkGroup')
          
    Role.with_deleted.
         where(type: %w(Group::FederalWorkGroup::Leader 
                        Group::StateWorkGroup::Leader 
                        Group::RegionalWorkGroup::Leader)).
         update_all(type: 'Group::WorkGroup::Leader')
         
    Role.with_deleted.
         where(type: %w(Group::FederalWorkGroup::Member 
                        Group::StateWorkGroup::Member 
                        Group::RegionalWorkGroup::Member)).
         update_all(type: 'Group::WorkGroup::Member')
    
    # coaches
    Role.with_deleted.
         where(type: %w(Group::State::Coach 
                        Group::Region::Coach)).
         update_all(type: 'Jubla::Role::Coach')
  end
  
  private
  
  def roles(type, layer)
    Role.with_deleted.
         joins('LEFT JOIN groups AS groups ON groups.id = roles.group_id ' + 
               'LEFT JOIN groups AS layer ON groups.layer_group_id = layer.id').
         where(type: type).
         where('layer.type = ?', layer)
  end
  
  def groups(type, layer)
    Group.with_deleted.
          joins('LEFT JOIN groups AS layer ON groups.layer_group_id = layer.id').
          where(type: type).
          where('layer.type = ?', layer)
  end
end
