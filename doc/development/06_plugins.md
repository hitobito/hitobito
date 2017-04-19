## Plugins / Wagons

Damit Hitobito lauffähig ist wird mindestens ein Wagon benötigt. In einem solchen Wagon kann neben der Grundkonfiguration das Verhalten der Applikation auf benutzerspezifische Bedürfnisse angepasst werden. Jeder Wagon wird in einem eigenen Gitrepo verwaltet.

### Wagonspezifische Anpassungen

#### Beispiel 1 - Pbs Person full_name

Im Pbs Wagon wurde die Methode "full_name" auf dem Person Model angepasst.

Die Implementation im Core sieht dabei folgendermassen aus: (hitobito/app/models/person.rb)

     def full_name(format = :default)
       case format
       when :list then "#{last_name} #{first_name}".strip
       else "#{first_name} #{last_name}".strip
       end
     end

Im Pbs Wagon gibt es ein entsprechendes Modul mit dem benutzerspezifischen Code für die Person Model Klasse: (hitobito_pbs/app/models/pbs/person.rb)
 
     module Pbs::Person
       ...
       extend ActiveSupport::Concern

       included do
         ...
         alias_method_chain :full_name, :title
         ...
       end
       ...

     def full_name_with_title(format = :default)
       case format
       when :list then full_name_without_title(format)
       else "#{title} #{full_name_without_title(format)}".strip
       end
     end

Mit "alias_method_chain" wird beim Aufruf von #full_name die Methode #full_name_with_title aufgerufen. Diese Methode wird ebenfalls in diesem Modul definiert. Die Implementation aus dem Core steht unter #full_name_without_title zur Verfügung.

Damit der Code in diesem Module entsprechend für das Person Model übernommen wird, wird dies in der wagon.rb entsprechend included: (hitobito_pbs/lib/hitobito_pbs/wagon.rb)


     module HitobitoPbs
       class Wagon < Rails::Engine
         include Wagons::Wagon
         ...
         Person.send       :include, Pbs::Person
         ...


