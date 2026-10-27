# Force the use of fallback fonts in Prawn, either by providing the argument `fallback_fonts`
# or by using the Export::Pdf::Document class instead of Prawn::Document directly.
Prawn::Document.prepend(Module.new do
  def initialize(options = {}, &_block)
    raise ArgumentError, <<~MSG unless options.key?(:fallback_fonts)
      In Hitobito we require you to initialize Prawn::Document with fallback_fonts argument.
      Instead you could simply use Export::Pdf::Document.
    MSG

    super
    fallback_fonts(options[:fallback_fonts])
  end
end)

# Render the Trix blocks unknown to prawn-markup as paragraphs.
Prawn::Markup::Processor.prepend(Module.new do
  def self.prepended(base)
    base.known_elements.push("blockquote", "pre")
  end

  def parse(html)
    super(html.to_s.gsub(%r{<pre\b[^>]*>.*?</pre>}m) { |pre| pre.gsub("\n", "<br>") })
  end

  def start_blockquote = start_div

  def end_blockquote = end_div

  def start_pre = start_div

  def end_pre = end_div
end)
