Fabricator(:wallets_pass_installation, class_name: "Wallets::PassInstallation") do
  pass_membership
  wallet_type { :google }
  state { :active }
  wallet_identifier { SecureRandom.uuid }
end
