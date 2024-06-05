# Implement wagon change 🚃

In Hitobito we make use of the wagons gem, which lets us overwrite the basic functionality of the core.

## Ruby Code 💎
When we want to overwrite a model to expand it with a function, we do that inside the `wagon.rb` file.
This looks something like that

`Group.include Pbs::Group`

With this line we define that the model `Group` should be overwritten by the `Pbs::Group` model. Inside the
`Pbs::Group` model it looks like this:

```
module Pbs::Group
  extend ActiveSupport::Concern
  
  included do
    self.used_attributes += [:website, :bank_account, :pbs_shortname]
    self.superior_attributes = [:pbs_shortname]
    
        validates :description, length: { allow_nil: true, maximum: 2**16 - 1 }
        validates :hostname, uniqueness: true, allow_blank: true
        has_many :crises
    
        root_types Group::Root
    
        def self.bund
          Group::Bund.first
        end
    
        def self.silverscouts
          Group::Silverscouts.first
        end
  end
  
  def active_crisis_acknowledgeable?(person)
  active_crisis && !active_crisis.acknowledged && active_crisis.creator != person
end
```

The first important step when overwriting a model is to create a module like the one above.
It should have the same name as the class you want to overwrite and it should extend the `ActiveSupport::Concern`
By extending this module you can then make use of  the `included do` block. Inside this block we define what attributes
and methods we need. After the include block you can then add the methods you want to add to the existing class.

## Settings ⚙️
If you have a more general change you want to make to a wagon, you can achieve that by visiting the settings.yml file of
the specific wagon. This is useful if you want to define a root email or if you want to disable statistic settings of the 
wagon.

## View 🌆
Another situation may be that you have to overwrite a view in your specific wagon. If that is the case
you want to visit first the `_form.html.haml` file of your entity. Now you'll see that we import there a lot of 
other files. Look into these templates you may find some line like this one:

`= render_extensions :custom_fields, locals: { f: f }`

This line renders as you may expect the `custom_fields` template. If we want to add a field to these `custom_fields` we 
navigate into our wagon and navigate in the same folder in which the custom_fields template lies inside the core. Once we found
this directory in our wagon, we have to create a file which is named similar to our `custom_fields` template. Since we need to
make this form change inside the pbs wagon, we name it: `_custom_fields_pbs.html.haml` . You should follow this convention
whenever possible `_template_name_wagon.html.haml`.

Once you defined this template rails will automatically overwrite the form with your custom additional field.





