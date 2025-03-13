#  Copyright (c) 2020, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

p = Person.first
p.assign_attributes(
    password: '1JuiZVwBO3Ms0thI',
    first_name: 'Puzzle',
    last_name: 'ITC',
    birthday: '1999-09-09'
)
p.save!(validate: false)

# The stamper is needed for some wagon seeds, specifically some mail notification jobs
# which mention the stamper (user that changed something) in the mail. During normal requests,
# the stamper is set to current_user, but during seeding this would be null.
Person.stamper = p
