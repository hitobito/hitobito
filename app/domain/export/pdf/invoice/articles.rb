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

      total_box
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
        column_widths: {0 => 290, 1 => 40, 2 => 50, 3 => 50, 4 => 50},
        cell_style: {borders: [:bottom],
                     border_color: "CCCCCC",
                     border_width: 0.5,
                     padding: [2, 0, 2, 0],
                     inline_format: true,})
    end

    def articles
      [
        [I18n.t("activerecord.models.invoice_article.one"),
         align_right(I18n.t("activerecord.attributes.invoice_item.count")),
         align_right(I18n.t("activerecord.attributes.invoice_item.unit_cost")),
         align_right(I18n.t("activerecord.attributes.invoice_item.cost")),
         align_right(I18n.t("activerecord.attributes.invoice_item.vat_rate")),],
      ] + article_data
    end

    def article_data
      invoice_items.collect do |it|
        [
          "<b>#{it.name}</b>\n#{it.description}",
          align_right(it.count.to_s),
          align_right(helper.number_to_currency(it.unit_cost, unit: "")),
          align_right(helper.number_to_currency(it.cost, unit: "")),
          align_right(helper.number_to_percentage(it.vat_rate, precision: 1)),
        ]
      end
    end

    def total_box # rubocop:disable Metrics/MethodLength
      bounding_box([0, cursor], width: bounds.width) do
        font_size(8) do
          pdf.table total_data, position: :right, cell_style: {borders: [],
                                                               border_color: "CCCCCC",
                                                               border_width: 0.5,} do
            rows(0..1).padding = [2, 0]

            row(2).font_style = :bold
            row(2).borders = [:bottom, :top]
            row(2).padding = [5, 0]
            row(2).column(0).padding = [5, 15, 5, 0]

            column(1).align = :right
          end
        end
      end
    end

    def total_data
      decorated = invoice.decorate
      [
        [I18n.t("invoices.pdf.cost"), decorated.cost],
        [I18n.t("invoices.pdf.total_vat"), decorated.vat],
        [I18n.t("invoices.pdf.total"), decorated.total],
      ]
    end

    def align_right(content)
      pdf.make_cell(content: content, align: :right)
    end
  end
end
