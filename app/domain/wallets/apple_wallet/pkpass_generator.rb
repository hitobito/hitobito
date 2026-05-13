# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Wallets
  module AppleWallet
    # Builds and signs .pkpass files
    #
    # The .pkpass format (Apple PassKit Package):
    # 1. pass.json — pass definition
    # 2. *.png — logo, icon, strip images
    # 3. manifest.json — SHA-1 hash of every file
    # 4. signature — PKCS#7 detached signature of manifest.json
    # 5. All packaged as a ZIP archive
    #
    # See: https://developer.apple.com/documentation/walletpasses/building_a_pass
    class PkpassGenerator
      def initialize
        raise "#{Config::FILE_PATH} not found" unless Config.exist?
      end

      # Create a signed .pkpass bundle with pass.json, images, and localized strings
      # pass_json: Hash with the pass structure (formatVersion, passTypeIdentifier, etc.)
      # images: Hash mapping filenames to binary data (e.g. "icon.png" => data, "logo.png" => data)
      # strings: Hash mapping filenames to string data
      #   (e.g. "pass.strings" => data, "de.lproj/pass.strings" => data)
      # See: https://developer.apple.com/documentation/walletpasses/building_a_pass
      def create_pass(pass_json, images = {}, strings = {})
        Dir.mktmpdir do |dir|
          write_pass_files(dir, pass_json, images, strings)
          write_manifest(dir)
          write_signature(dir)
          package_zip(dir)
        end
      end

      private

      def write_pass_files(dir, pass_json, images, strings)
        File.write(File.join(dir, "pass.json"), pass_json.to_json)
        images.each do |name, data|
          safe_name = File.basename(name)
          File.binwrite(File.join(dir, safe_name), data)
        end
        strings.each do |name, data|
          safe_name = File.basename(name)
          File.write(File.join(dir, safe_name), data)
        end
      end

      def write_manifest(dir)
        manifest = {}
        Dir[File.join(dir, "*")].each do |file|
          manifest[File.basename(file)] = Digest::SHA1.hexdigest(File.binread(file))
        end
        File.write(File.join(dir, "manifest.json"), manifest.to_json)
      end

      # Sign manifest.json with PKCS#7 detached signature
      def write_signature(dir)
        p12 = OpenSSL::PKCS12.new(
          File.binread(Config.p12_certificate_path),
          Config.p12_password
        )
        wwdr = OpenSSL::X509::Certificate.new(
          File.binread(Config.wwdr_certificate_path)
        )
        signature = OpenSSL::PKCS7.sign(
          p12.certificate, p12.key,
          File.read(File.join(dir, "manifest.json")),
          [wwdr],
          OpenSSL::PKCS7::BINARY | OpenSSL::PKCS7::DETACHED
        )
        File.binwrite(File.join(dir, "signature"), signature.to_der)
      end

      def package_zip(dir)
        buffer = Zip::OutputStream.write_buffer do |zip|
          Dir[File.join(dir, "*")].each do |file|
            zip.put_next_entry(File.basename(file))
            zip.write(File.binread(file))
          end
        end
        buffer.string
      end
    end
  end
end
