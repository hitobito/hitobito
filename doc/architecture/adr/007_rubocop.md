# ADR-007 Rubocop & Standardrb

Status: **Entscheid**

Entscheid: **Wir linten und fix mit rubocop und integriertem standardrb ruleset**

Rubocop macht code analyse und formatierungen. Beim Formatieren wollen wir aber möglichst nah an
standard.rb bleiben. Dabei wollen wir aber nicht 2 tools einsetzen.

Somit wurde rubocop mit standard.rb ruleset analog zu konfiguriert. Aufwendiger zu behebende
Violation wurden in [../../../.rubocop_todo.yml](../../../.rubocop_todo.yml) ignoriert

Entwickler werden aufgefordert ihre Entwicklungsumgebung so zu adaptieren, dass auto-format und
linting in die Entwicklungsumgebung integriert (on-save), wie dies zb mit
[ruby-lsp](https://github.com/Shopify/ruby-lsp) geschieht.

### References

https://www.fastruby.io/blog/ruby/code-quality/how-we-use-rubocop-and-standardrb.html
https://evilmartians.com/chronicles/rubocoping-with-legacy-bring-your-ruby-code-up-to-standard
https://shopify.github.io/ruby-lsp/RubyLsp/Requests/Formatting.html
