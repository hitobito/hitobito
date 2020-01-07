# encoding: utf-8

#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe AsyncDownloadsController do

  let(:person) { people(:bottom_member) }

  before do
    sign_in(person)
  end

  context 'show' do
    it 'sends file deletes cookies if current_person has access and last download' do
      filename = AsyncDownloadFile.create_name('test', person.id)
      Cookies::AsyncDownload.new(cookies).set(name: filename, type: 'txt')
      generate_test_file(filename)

      get :show, id: filename, file_type: 'txt'

      expect(response.body).to match('this is a testfile')
      expect(response.status).to match(200)
      expect(cookies[Cookies::AsyncDownload::NAME]).to be_nil
    end

    it 'sends file removes cookie entry if current_person has access and not last download' do
      filename = AsyncDownloadFile.create_name('test', person.id)
      Cookies::AsyncDownload.new(cookies).set(name: filename, type: 'txt')
      Cookies::AsyncDownload.new(cookies).set(name: 'second_download', type: 'txt')
      generate_test_file(filename)

      get :show, id: filename, file_type: 'txt'

      cookie = JSON.parse(cookies[Cookies::AsyncDownload::NAME])

      expect(response.body).to match('this is a testfile')
      expect(response.status).to match(200)
      expect(cookie).not_to be_nil
      expect(cookie).to be_one
      expect(cookie[0]['name']).not_to match(/^#{filename}/)
      expect(cookie[0]['name']).to match(/^second_download/)
    end

    it 'returns 404 if person has no access' do
      filename = AsyncDownloadFile.create_name('test', 1234) # random person_id
      generate_test_file(filename)

      get :show, id: filename, file_type: 'txt'

      is_expected.to render_template('errors/404')
      expect(response.status).to match(404)
    end

    it 'returns 404 if file does not exists' do
      get :show, id: 'unknown_file', file_type: 'txt'

      is_expected.to render_template('errors/404')
      expect(response.status).to match(404)
    end
  end

  context 'csv' do
    xit 'sends file with specific encoding' do
      allow(Settings.csv).to receive_messages(encoding: 'ISO-8859-1')
      filename = AsyncDownloadFile.create_name('test', person.id)
      Cookies::AsyncDownload.new(cookies).set(name: filename, type: 'csv')
      generate_test_file(filename, :csv)

      get :show, id: filename, file_type: 'csv'

      expect(response.body).to match('this is a testfile')
      expect(response.body.encoding.to_s).to eq('ISO-8859-1')
    end
  end

  context 'exist' do
    it 'render json status 200 if file exists and person has access' do
      filename = AsyncDownloadFile.create_name('test', person.id)
      generate_test_file(filename)

      get :exists?, id: filename, file_type: 'txt', format: :json

      json = JSON.parse(@response.body)
      expect(json['status']).to match(200)
    end

    it 'render json status 404 if person has no access' do
      filename = AsyncDownloadFile.create_name('test', 1234) # random person_id
      generate_test_file(filename)

      get :exists?, id: filename, file_type: 'txt', format: :json

      json = JSON.parse(@response.body)
      expect(json['status']).to match(404)
    end

    it 'render json status 404 if file does not exist' do
      get :exists?, id: 'unknown_file', file_type: 'txt', format: :json

      json = JSON.parse(@response.body)
      expect(json['status']).to match(404)
    end
  end

  private

  def generate_test_file(filename, filetype = :txt)
    AsyncDownloadFile.new(filename, filetype).write('this is a testfile')
  end
end
