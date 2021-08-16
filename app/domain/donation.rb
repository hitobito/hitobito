# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_die_mitte.

class Donation
  def initialize
    @donations = Payment.list
  end

  def in_last(duration)
    raise 'Has to be at least one year in the past' if duration.ago.year >= Time.zone.now.year

    from = duration.ago.beginning_of_year
    to = 1.year.ago.end_of_year
    @donations = @donations.where('payments.received_at >= ?' \
                                  'AND payments.received_at <= ?', from, to)

    self
  end

  def of_person(person)
    @donations = @donations.joins(:invoice).where(invoices: { recipient: person })

    self
  end

  def in_layer(layer)
    @donations = @donations.joins(:invoice).where(invoices: { group: layer })

    self
  end

  def previous_amount(options = {})
    if options[:increased_by]
      increased_amount = donation_sum * (1.0 + options[:increased_by].to_f/100.0)
      case donation_sum
      when 0..99
        round_to_nearest(5.0, increased_amount)
      when 100..999
        round_to_nearest(10.0, increased_amount)
      else
        round_to_nearest(50.0, increased_amount)
      end
    else
      donation_sum
    end
  end

  def donation_sum
    @donations.sum(:amount)
  end

  def round_to_nearest(target, value)
    (value / target.to_f).round * target.to_f
  end
end
