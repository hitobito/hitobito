Mail.defaults do
  retriever_method(Settings.email.retriever.type.to_sym,
                   Settings.email.retriever.config.to_hash)
end