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
      attr_reader :config

      def initialize(config = Config)
        @config = config
        raise "#{config::FILE_PATH} not found" unless config.exist?
      end

      # Create a signed .pkpass bundle with pass.json, images, and localized strings
      # pass_json: Hash with the pass structure (formatVersion, passTypeIdentifier, etc.)
      # images: Hash mapping filenames to binary data (e.g. "icon.png" => data, "logo.png" => data)
      # strings: Hash mapping filenames to string data
      #   (e.g. "pass.strings" => data, "de.lproj/pass.strings" => data)
      def create_pass(pass_json, images = {}, strings = {})
        Dir.mktmpdir do |dir|
          write_pass_files(dir, pass_json, images, strings)
          write_manifest(dir)
          write_signature(dir)
          package_zip(dir)
        end
      end

      private

      # Write pass.json, images, and localized strings to the temporary directory
      def write_pass_files(dir, pass_json, images, strings)
        File.write(File.join(dir, "pass.json"), pass_json.to_json)
        images.each do |name, data|
          write_file_with_directories(dir, name, data, binary: true)
        end
        strings.each do |name, data|
          write_file_with_directories(dir, name, data, binary: false)
        end
      end

      # Write file to directory, creating subdirectories if needed (e.g., de.lproj/)
      def write_file_with_directories(base_dir, name, data, binary:)
        full_path = File.join(base_dir, name)
        FileUtils.mkdir_p(File.dirname(full_path))
        if binary
          File.binwrite(full_path, data)
        else
          File.write(full_path, data)
        end
      end

      # Write manifest.json containing SHA-1 hashes of all files in the pass package
      def write_manifest(dir)
        manifest = build_manifest(dir)
        File.write(File.join(dir, "manifest.json"), manifest.to_json)
      end

      # Build manifest hash mapping filenames to their SHA-1 hashes
      # Recursively includes files in subdirectories (e.g., de.lproj/pass.strings)
      def build_manifest(dir)
        Dir.glob(File.join(dir, "**", "*")).select { |f|
          File.file?(f)
        }.each_with_object({}) do |file, hash|
          relative_path = file.sub("#{dir}/", "")
          hash[relative_path] = calculate_file_hash(file)
        end
      end

      # Calculate SHA-1 hash of a file
      def calculate_file_hash(file)
        Digest::SHA1.hexdigest(File.binread(file))
      end

      # Sign manifest.json with PKCS#7 detached signature
      def write_signature(dir)
        signature = create_signature(dir)
        File.binwrite(File.join(dir, "signature"), signature.to_der)
      end

      # Create PKCS#7 detached signature of the manifest.json file
      # Uses the pass certificate and WWDR certificate chain
      # See: https://ruby-doc.org/stdlib/libdoc/openssl/rdoc/OpenSSL/PKCS7.html
      def create_signature(dir)
        OpenSSL::PKCS7.sign(
          config.certificate,
          config.key,
          File.read(File.join(dir, "manifest.json")),
          [config.wwdr_certificate],
          OpenSSL::PKCS7::BINARY | OpenSSL::PKCS7::DETACHED
        )
      end

      # Package all pass files into a ZIP archive (.pkpass format)
      # Preserves directory structure for localized files (e.g., de.lproj/pass.strings)
      def package_zip(dir)
        buffer = Zip::OutputStream.write_buffer do |zip|
          Dir.glob(File.join(dir, "**", "*")).select { |f| File.file?(f) }.each do |file|
            relative_path = file.sub("#{dir}/", "")
            zip.put_next_entry(relative_path)
            zip.write(File.binread(file))
          end
        end
        buffer.string
      end
    end
  end
end
