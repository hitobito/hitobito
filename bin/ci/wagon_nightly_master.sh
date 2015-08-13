#  Copyright (c) 2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


# Runs a wagon nightly build for the master branch

. hitobito/bin/ci/wagon_setup.sh

bundle exec rake db:create ci:wagon:nightly --trace &&
bundle exec rake wagon:exec CMD='rake app:tarantula:test app:tx:auth app:tx:push' --trace
