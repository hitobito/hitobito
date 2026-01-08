# frozen_string_literal: true

#  Copyright (c) 2025, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Sftp do
  let(:config) do
    {
      host: "sftp.local",
      port: 22,
      user: "hitobito",
      password: "password",
      private_key: "private key",
      remote_path: "upload/path"
    }
  end
  let(:session) { instance_double("Net::SFTP::Session", connect!: true) }

  subject(:sftp) { Sftp.new(config) }

  before { allow_any_instance_of(Sftp).to receive(:server_version).and_return("unknown") }

  context "with password" do
    before { config.delete(:private_key) }

    it "creates connection with password credential" do
      expect(::Net::SFTP).to receive(:start)
        .with("sftp.local", "hitobito", {
          password: "password",
          non_interactive: true,
          port: 22
        })
        .and_return(session)

      sftp.send(:connection)
    end
  end

  context "with private key" do
    before { config.delete(:password) }

    it "creates connection with private key" do
      expect(::Net::SFTP).to receive(:start)
        .with("sftp.local", "hitobito", {
          key_data: ["private key"],
          non_interactive: true,
          port: 22
        })
        .and_return(session)

      sftp.send(:connection)
    end
  end

  context "with private key and password" do
    it "creates connection with private key" do
      expect(::Net::SFTP).to receive(:start)
        .with("sftp.local", "hitobito", {
          key_data: ["private key"],
          non_interactive: true,
          port: 22
        })
        .and_return(session)

      sftp.send(:connection)
    end
  end

  describe "#upload_file" do
    let(:file_path) { "sektionen/1650/Adressen_00001650.csv" }

    before do
      allow(::Net::SFTP).to receive(:start).and_return(session)
      allow(session).to receive(:upload!)
    end

    it "does not create directories when they already exist" do
      allow(sftp).to receive(:directory?).and_return(true)

      expect(sftp).not_to receive(:create_remote_dir)

      sftp.upload_file("data", file_path)
    end

    it "creates missing directories in the path" do
      allow(sftp).to receive(:directory?).and_return(false)

      expect(sftp).to receive(:create_remote_dir).with(Pathname.new("sektionen"))
      expect(sftp).to receive(:create_remote_dir).with(Pathname.new("sektionen/1650"))

      sftp.upload_file("data", file_path)
    end

    it "does not create directories on AWS SFTP" do
      allow(sftp).to receive(:server_version).and_return("AWS_SFTP")

      expect(sftp).not_to receive(:create_remote_dir)

      sftp.upload_file("data", "some/deep/path/file.csv")
    end

    it "preserves binary encoding of uploaded data" do
      allow(sftp).to receive(:create_directories?).and_return(false)

      original_data = "thîs îs a ßtrïng în ISO-8859-1 énçødîñg".encode("ISO-8859-1")

      expect(session).to receive(:upload!) do |local_path, _remote_path|
        expect(File.binread(local_path).bytes).to eq original_data.bytes
      end

      sftp.upload_file(original_data, file_path)
    end
  end

  describe "#create_remote_dir" do
    before do
      allow(::Net::SFTP).to receive(:start).and_return(session)
    end

    it "creates directory on remote server" do
      expect(session).to receive(:mkdir!).with("test_directory")

      sftp.create_remote_dir("test_directory")
    end
  end

  describe "connection error handling" do
    it "raises ConnectionError when Net::SFTP.start fails" do
      allow(::Net::SFTP).to receive(:start)
        .and_raise(SocketError.new("Connection refused"))

      expect { sftp.send(:connection) }.to raise_error(Sftp::ConnectionError)
    end
  end
end
