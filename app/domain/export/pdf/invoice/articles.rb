# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Invoice
  class Articles < Section
    attr_reader :reminder

    def render # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      reminder = invoice.payment_reminders.last

      move_cursor_to 510
      font_size(12) { text title(reminder) }
      pdf.move_down 8
      text invoice.description

      if reminder
        pdf.move_down 8
        font_size(10) { text reminder.text }
      end

      pdf.move_down 10
      pdf.font_size(8) { articles_table }

      total_box unless invoice.hide_total?
      pdf.move_down 4
      font_size(8) { text invoice.payment_information }
    end

    private

    def title(reminder)
      reminder ? "#{reminder.title} - #{invoice.title}" : invoice.title
    end

    def articles_table
      table(articles,
            header: true,
            column_widths: { 0 => 290, 1 => 40, 2 => 50, 3 => 50, 4 => 50 },
            cell_style: { borders: [:bottom],
                          border_color: 'CCCCCC',
                          border_width: 0.5,
                          padding: [2, 0, 2, 0],
                          inline_format: true })
    end

    def articles
      [
        [I18n.t('activerecord.models.invoice_article.one'),
         align_right(I18n.t('activerecord.attributes.invoice_item.count')),
         align_right(I18n.t('activerecord.attributes.invoice_item.unit_cost')),
         align_right(I18n.t('activerecord.attributes.invoice_item.cost')),
         align_right(I18n.t('activerecord.attributes.invoice_item.vat_rate'))]
      ] + article_data
    end

    def article_data
      invoice_items.collect do |it|
        [
          "<b>#{it.name}</b>\n#{it.description}",
          align_right(it.count.to_s),
          align_right(helper.number_to_currency(it.unit_cost, unit: '')),
          align_right(helper.number_to_currency(it.cost, unit: '')),
          align_right(helper.number_to_percentage(it.vat_rate, precision: 1))
        ]
      end
    end

    def total_box # rubocop:disable Metrics/MethodLength
      bounding_box([0, cursor], width: bounds.width) do
        font_size(8) do
          data = total_data
          payments = invoice.payments
          pdf.table data, position: :right,
                          column_widths: { 0 => 100 },
                          cell_style: { borders: [],
                                        border_color: 'CCCCCC',
                                        border_width: 0.5 } do
            last_row_index = data.size.pred
            rows(0..last_row_index).padding = [2, 0]

            row(last_row_index).font_style = :bold

            total_row_index = payments.any? ? last_row_index - payments.count.succ : last_row_index
            row(total_row_index).font_style = :bold

            row(last_row_index).borders = [:bottom, :top]
            row(last_row_index).padding = [5, 0]
            row(last_row_index).column(0).padding = [5, 15, 5, 0]

            column(1).align = :right
          end
        end
      end
    end

    def total_data
      decorated = invoice.decorate
      vat_row = if invoice.calculated[:vat].nonzero?
                  [I18n.t('invoices.pdf.total_vat'), decorated.vat]
                end
      payment_data = if invoice.payments.any?
                       payment_rows +
                         [[I18n.t('invoices.pdf.amount_open'), decorated.amount_open]]
                     end

      [
        [I18n.t('invoices.pdf.cost'), decorated.cost],
        vat_row,
        [I18n.t('invoices.pdf.total'), decorated.total],
        *payment_data
      ].compact
    end

    def payment_rows
      @payment_rows ||= invoice.payments.map do |p|
        [I18n.t('invoices.pdf.payment'), invoice.decorate.format_currency(p.amount)]
      end
    end

    def align_right(content)
      pdf.make_cell(content: content, align: :right)
    end
  end
end
