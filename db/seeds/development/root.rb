# encoding: utf-8

#  Copyright (c) 2020, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

p = Person.first
p.assign_attributes(
    password: 'hito42bito',
    first_name: 'Puzzle',
    last_name: 'ITC',
    birthday: '1999-09-09'
)
p.save!(validate: false)
