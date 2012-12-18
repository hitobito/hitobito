class ExtractDifferentGroupTypes < ActiveRecord::Migration
  def up
    # work groups
    update_types(:groups, 'Group::WorkGroup', 'Group::Federation', 'Group::FederalWorkGroup')
    update_types(:roles, 'Group::WorkGroup::Leader', 'Group::Federation', 'Group::FederalWorkGroup::Leader')
    update_types(:roles, 'Group::WorkGroup::Member', 'Group::Federation', 'Group::FederalWorkGroup::Member')
    
    update_types(:groups, 'Group::WorkGroup', 'Group::State', 'Group::StateWorkGroup')
    update_types(:roles, 'Group::WorkGroup::Leader', 'Group::State', 'Group::StateWorkGroup::Leader')
    update_types(:roles, 'Group::WorkGroup::Member', 'Group::State', 'Group::StateWorkGroup::Member')
    
    update_types(:groups, 'Group::WorkGroup', 'Group::Region', 'Group::RegionalWorkGroup')
    update_types(:roles, 'Group::WorkGroup::Leader', 'Group::Region', 'Group::RegionalWorkGroup::Leader')
    update_types(:roles, 'Group::WorkGroup::Member', 'Group::Region', 'Group::RegionalWorkGroup::Member')
    
    
    # professional groups
    update_types(:groups, 'Group::ProfessionalGroup', 'Group::Federation', 'Group::FederalProfessionalGroup')
    update_types(:roles, 'Group::ProfessionalGroup::Leader', 'Group::Federation', 'Group::FederalProfessionalGroup::Leader')
    update_types(:roles, 'Group::ProfessionalGroup::Member', 'Group::Federation', 'Group::FederalProfessionalGroup::Member')
    
    update_types(:groups, 'Group::ProfessionalGroup', 'Group::State', 'Group::StateProfessionalGroup')
    update_types(:roles, 'Group::ProfessionalGroup::Leader', 'Group::State', 'Group::StateProfessionalGroup::Leader')
    update_types(:roles, 'Group::ProfessionalGroup::Member', 'Group::State', 'Group::StateProfessionalGroup::Member')
    
    update_types(:groups, 'Group::ProfessionalGroup', 'Group::Region', 'Group::RegionalProfessionalGroup')
    update_types(:roles, 'Group::ProfessionalGroup::Leader', 'Group::Region', 'Group::RegionalProfessionalGroup::Leader')
    update_types(:roles, 'Group::ProfessionalGroup::Member', 'Group::Region', 'Group::RegionalProfessionalGroup::Member')
    
    
    # coaches
    update_types(:roles, 'Jubla::Role::Coach', 'Group::State', 'Group::State::Coach')
    update_types(:roles, 'Jubla::Role::Coach', 'Group::Region', 'Group::Region::Coach')
    
    
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
  
  def update_types(kind, old_type, layer, new_type)
    key = mysql? ? "#{kind}.type" : 'type'
    send(kind, old_type, layer).update_all("#{key} = '#{new_type}'")
  end
  
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
  
  def mysql?
    Role.connection.adapter_name.downcase =~ /mysql/
  end
end
