require 'spec_helper'

describe AppStatus::Store do

  let(:app_status) { AppStatus::Store.new }

  context 'app healthy' do

    it '#code' do
      expect(app_status.code).to eq(:ok)
    end

    it '#store_ok?' do
      expect(app_status.send(:store_ok?)).to eq(true)
    end

  end

  context 'store unhealthy' do

    it 'folder does not exist' do
      expect(File).to receive(:directory?).and_return(false)
      expect(app_status.code).to eq(:service_unavailable)
    end

    it 'folder is not writeable' do
      expect(File).to receive(:writable?).and_return(false)
      expect(app_status.code).to eq(:service_unavailable)
    end

  end
end
