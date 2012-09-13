require 'ostruct'
class GroupExhibit < DisplayCase::Exhibit
  extend Forwardable
  def_delegators :context, :content_tag


  def self.applicable_to?(object)
    object.class.name == 'Group' || object.class.base_class.name == 'Group'
  end

  def self.custom_fields
    @types ||= {
      federalboard: [:bank_account],
      organizationboard: [],
      state: [],
      professionalgroup: [],
      workgroup: [],
      simplegroup: []
    }
  end

  def possible_types
    spacer = OpenStruct.new(human: "")
    [spacer] + parent.class.possible_children.collect(&:model_name)
  end

  def type_selection(f)
    f.labeled_collection_select :type, possible_types, :to_s, :human, {}, attrs_for_remote
  end

  def attrs_for_remote
    url = context.fields_groups_path(group: { parent_id: parent.id })
    url = URI.unescape(url)
    { data: { remote: true, replace: true, url: url }  } 
  end

  def custom_fields(f)
    markup = ""
    custom_fields = GroupExhibit.custom_fields[type_as_sym] || []
    custom_fields.each do |field|
      markup << custom_field(f, field)
    end
    markup.html_safe
  end

  def type_as_sym
    type && type.split('::').last.downcase.to_sym
  end

  def custom_field(f, field)
    f.labeled_input_field(field)
  end

end
