# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Invoice
  class Articles < Section

    def render
      bounding_box([0, 510], width: bounds.width) do
        font_size(12) { text invoice.title }
        pdf.move_down 10
        pdf.font_size(8) do
          articles_table
        end
      end
      total_box
    end

    private

    def articles_table
      table articles, header: true, column_widths: { 0 => 290, 1 => 50, 2 => 60, 3 => 80 },
                      cell_style: { borders: [:bottom],
                                    border_color: 'CCCCCC',
                                    border_width: 0.5,
                                    padding: [2, 0, 2, 0],
                                    inline_format: true } do

        style(row(0), align: :center, font_style: :bold)
        style(column(0), align: :left)
        style(columns(1..3), align: :right)
      end
    end


    def articles
      [
        [I18n.t('activerecord.models.invoice_article.one'),
         I18n.t('activerecord.attributes.invoice_items.count'),
         I18n.t('activerecord.attributes.invoice_items.unit_cost'),
         I18n.t('activerecord.attributes.invoice_items.cost')]
      ] + article_data
    end

    def article_data
      invoice_items.collect do |it|
        [
          "<b>#{it.name}</b>\n#{it.description}",
          it.count,
          helper.number_to_currency(it.unit_cost, unit: ''),
          helper.number_to_currency(it.cost, unit: '')
        ]
      end
    end

    def total_box
      bounding_box([0, cursor], width: bounds.width) do
        font_size(10) do
          table total_data, position: :right, cell_style: { borders: [:bottom],
                                                            border_color: 'CCCCCC',
                                                            border_width: 0.5 } do
            style(row(1).column(0), size: 8)
            style(column(1), align: :right)
          end
        end
      end
    end

    def total_data
      [
        [I18n.t('invoices.pdf.total'),
         helper.number_to_currency(invoice.calculated[:total], format: '%n %u')],
        [I18n.t('invoices.pdf.total_vat'),
         helper.number_to_currency(invoice.calculated[:vat], format: '%n %u')]
      ]
    end
  end
end
