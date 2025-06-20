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
