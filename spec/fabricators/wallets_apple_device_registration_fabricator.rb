Fabricator(:wallets_apple_device_registration,
  class_name: "Wallets::AppleWallet::DeviceRegistration") do
  pass_installation { Fabricate(:wallets_pass_installation, wallet_type: :apple) }
  device_library_identifier { SecureRandom.hex(16) }
  push_token { SecureRandom.hex(32) }
end
