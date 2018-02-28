# encoding: utf-8

#  Copyright (c) 2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
class Invoice::BatchUpdateResult

  def track_update(key, invoice)
    updates[key.to_sym] << invoice
  end

  def track_error(key, invoice)
    errors[key.to_sym] << invoice
  end

  def to_s
    update_lines + error_lines
  end

  def updates
    @updates ||= Hash.new { |h, k| h[k] = [] }
  end

  def errors
    @errors ||= Hash.new { |h, k| h[k] = [] }
  end

  private

  def update_lines

  end

  def error_lines

  end

end


