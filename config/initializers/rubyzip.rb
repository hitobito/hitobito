#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# rubyzip 3 adds Zip64 headers to every streamed entry, which some readers reject.
# zip64 is only needed for archives bigger than 4GB or with a lot of files. Both
# is currently not needed by hitobito. Reading such files should work, but we do
# not have such a feature as of this writing.
Zip.write_zip64_support = false
