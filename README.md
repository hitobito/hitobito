# Welcome to hitobito

hitobito is an open source web application to manage complex group hierarchies with members, events and a lot more.

[![Build Status](https://travis-ci.org/hitobito/hitobito.svg?branch=master)](https://travis-ci.org/hitobito/hitobito)
[![Open Source Helpers](https://www.codetriage.com/hitobito/hitobito/badges/users.svg)](https://www.codetriage.com/hitobito/hitobito)

## Development

Hitobito is a Ruby on Rails application that runs on Ruby >= 2.5 and Rails 6.
It might run with minor tweaks on older Rubies, but is not tested against those
versions.

To get going, after you got a copy of hitobito and at least one wagon with an organization
structure setup as described below, issue the following commands in the main directory:

    sudo yum install mysql memcached sphinxsearch imagemagick  # install system dependencies

    bundle               # install gem dependencies
    rake db:create       # create a development database
    rake db:setup:all    # run migrations and load seed data of the app and all wagons
    rails server         # start the rails server

To start the search server, run background jobs or the development mail catcher, run:

    rake ts:start
    rake jobs:work
    mailcatcher -v -f

A more detailed development documentation in German can be found in [doc/development](doc/development).
This is where you also find some [Deployment Instructions](doc/development/02_deployment.md).

## Architecture

The architecture documentation in German can be found in [doc/architecture](doc/architecture).

Two topics shall be mentioned here explicitly:

### Group Hierarchy

hitobito provides a powerful meta-model to describe group structures.
Groups are always of a specific type and are arranged in a tree.
Each group type may have several different role types.

This core part of hitobito does not provide any specific group or role types.
They have to be defined in a separate plugin, specific to your organization structure.

An example group type definition might look like this:

    class Group::Layer < Group
      self.layer = true

      children Group::Layer, Group::Board, Group::Basic

      class Role < Leader
        self.permissions = [:layer_full, :contact_data]
      end

      class Member < Role
        self.permissions = [:group_read]
      end

      roles Leader, Member
    end

A group type always inherits from the class `Group`.
It may be a layer, which defines a set of groups that are in a common permission range.
All subgroups of a layer group belong to this range unless a subgroup is a layer itself.

Then all possible child types of the group are listed.
When creating subgroups, only these types will be allowed.
As shown, types may be organized recursively.

For the ease of maintainability, role types may be defined directly in the group type.
Each role type has a set of permissions.
They are general indications of what and where.
All specific abilities of a user are derived from the role permissions she has in her different groups.

See [Gruppen- und Rollentypen](doc/architecture/08_konzepte.md) for more details and
[hitobito_generic](https://github.com/hitobito/hitobito_generic) for a complete example group
structure.


### Plugin architecture

hitobito is built on the plugin framework [Wagons](http://github.com/codez/wagons).
With Wagons, arbitrary features and extensions may be created for hitobito.
As mentioned above, as there are no group types coming from hitobito itself,
at least one wagon is required to define group types in order to use hitobito.

See [Wagon Guidelines](doc/development/04_wagons.md) or [Wagons](http://github.com/codez/wagons)
for more information on wagons and its available rake tasks.


## License

hitobito is released under the GNU Affero General Public License.
Copyright 2012-2015 by Jungwacht Blauring Schweiz, Puzzle ITC GmbH, Pfadibewegung Schweiz,
CEVI Regionalverband ZH-SH-GL, Insieme Schweiz.
See COPYING for more details.

hitobito was developed by [Puzzle ITC GmbH](http://puzzle.ch).

The hitobito logo is a registered trademark of hitobito LTD, Switzerland. Please contact [KunoKunz](https://github.com/KunoKunz) if you want to use the logo and be part of our community.
