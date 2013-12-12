require 'spec_helper'

describe 'StandardTableBuilder' do

  include StandardHelper

  let(:entries) { %w(foo bahr) }
  let(:table)   { StandardTableBuilder.new(entries, self) }

  def format_size(obj) #:nodoc:
    "#{obj.size} chars"
  end

  specify '#html_header' do
    table.attrs :upcase, :size
    dom = '<tr><th>Upcase</th><th>Size</th></tr>'
    assert_dom_equal dom, table.send(:html_header)
  end

  specify 'single attr row' do
    table.attrs :upcase, :size
    dom = '<tr><td>FOO</td><td>3 chars</td></tr>'
    assert_dom_equal dom, table.send(:html_row, entries.first)
  end

  specify 'custom row' do
    table.col('Header', class: 'hula') { |e| "Weights #{e.size} kg" }
    dom = '<tr><td class="hula">Weights 3 kg</td></tr>'
    assert_dom_equal dom, table.send(:html_row, entries.first)
  end

  context 'attr col' do
    let(:col) { table.cols.first }

    context 'output' do
      before { table.attrs :upcase }

      it { col.html_header.should == '<th>Upcase</th>' }
      it { col.content('foo').should == 'FOO' }
      it { col.html_cell('foo').should == '<td>FOO</td>' }
    end

    context 'content with custom format_size method' do
      before { table.attrs :size }

      it { col.content('abcd').should == '4 chars' }
    end
  end

  specify 'two x two table' do
    dom = <<-FIN
      <table>
      <thead>
      <tr><th>Upcase</th><th>Size</th></tr>
      </thead>
    <tbody>
      <tr><td>FOO</td><td>3 chars</td></tr>
      <tr><td>BAHR</td><td>4 chars</td></tr>
      </tbody>
      </table>
    FIN
    dom.gsub!(/[\n\t]/, '').gsub!(/\s{2,}/, '')

    table.attrs :upcase, :size

    assert_dom_equal dom, table.to_html
  end

  specify 'table with before and after cells' do
    dom = <<-FIN
      <table>
      <thead>
      <tr><th class='left'>head</th><th>Upcase</th><th>Size</th><th></th></tr>
      </thead>
      <tbody>
      <tr>
        <td class='left'><a href='/'>foo</a></td>
        <td>FOO</td>
        <td>3 chars</td>
        <td>Never foo</td>
      </tr>
      <tr>
        <td class='left'><a href='/'>bahr</a></td>
        <td>BAHR</td>
        <td>4 chars</td>
        <td>Never bahr</td>
      </tr>
      </tbody>
      </table>
    FIN
    dom.gsub!(/[\n\t]/, '').gsub!(/\s{2,}/, '')

    table.col('head', class: 'left') { |e| link_to e, '/' }
    table.attrs :upcase, :size
    table.col { |e| "Never #{e}" }

    assert_dom_equal dom, table.to_html
  end

  specify 'empty entries collection renders empty table' do
    dom = <<-FIN
      <table>
      <thead>
      <tr><th class='left'>head</th><th>Upcase</th><th>Size</th><th></th></tr>
      </thead>
      <tbody>
      </tbody>
      </table>
    FIN
    dom.gsub!(/[\n\t]/, '').gsub!(/\s{2,}/, '')

    table = StandardTableBuilder.new([], self)
    table.col('head', class: 'left') { |e| link_to e, '/' }
    table.attrs :upcase, :size
    table.col { |e| "Never #{e}" }

    assert_dom_equal dom, table.to_html
  end

end
