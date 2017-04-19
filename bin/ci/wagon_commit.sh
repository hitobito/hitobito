#  Copyright (c) 2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


# Runs a wagon commit build

. hitobito/bin/ci/wagon_setup.sh

bundle exec rake db:drop db:create ci:wagon --trace
