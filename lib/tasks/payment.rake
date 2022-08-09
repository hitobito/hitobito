# frozen_string_literal: true

#  Copyright (c) 2022, Die Mitte Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

namespace :payment do
  desc 'Exports payments without invoices'
  task :export_without_invoice, [:from, :to] => :environment do |_t, args|
    from, to = daterange_args(args)

    payments = Payments::Collection.new
                                   .from(from)
                                   .to(to)
                                   .without_invoices
                                   .payments

    if payments.empty?
      puts 'No payments found'
      exit
    end

    path = "/tmp/non_assigned_payments_#{from}-#{to}.csv"
    export(path, payments)
  end

  task :export_ebics_imported, [:from, :to] => :environment do |_t, args|
    from, to = daterange_args(args)

    payments = Payments::Collection.new
                                   .from(from)
                                   .to(to)
                                   .where(status: :ebics_imported)
                                   .payments

    if payments.empty?
      puts 'No payments found'
      exit
    end

    path = "/tmp/ebics_imported_payments_#{from}-#{to}.csv"
    export(path, payments)
  end

  private

  def daterange_args(args)
    from = args[:from].present? ? Date.parse(args[:from]) : 1.month.ago.to_date
    to = args[:to].present? ? Date.parse(args[:to]) : Time.zone.today

    [from, to]
  end

  def export(filepath, payments)
    File.open(filepath, 'w') do |f|
      f.write Export::Tabular::Payments::List.csv(payments)
    end

    puts "Saved payments to #{filepath}"
  end
end
