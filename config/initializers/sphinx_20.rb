# Config for Sphinx < 2.1
version = ThinkingSphinx::Configuration.instance.controller.sphinx_version
if version.nil? || version < '2.1'
  ThinkingSphinx::SphinxQL.variables!

  ThinkingSphinx::Middlewares::DEFAULT.insert_after(
    ThinkingSphinx::Middlewares::Inquirer, ThinkingSphinx::Middlewares::UTF8
  )
  ThinkingSphinx::Middlewares::RAW_ONLY.insert_after(
    ThinkingSphinx::Middlewares::Inquirer, ThinkingSphinx::Middlewares::UTF8
  )
end
