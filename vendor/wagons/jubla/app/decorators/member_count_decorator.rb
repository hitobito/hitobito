class MemberCountDecorator < ApplicationDecorator
  decorates :member_count
  
  %w(leader child).each do |role|
    %w(m f).each do |sex|
      define_method "#{role}_#{sex}_string" do
        model.send("#{role}_#{sex}") || '-'
      end
    end
  end
end