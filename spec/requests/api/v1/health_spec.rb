require 'rails_helper'

RSpec.describe 'Api::V1::Health', type: :request do
  describe 'GET /api/v1/health' do
    it 'returns a successful response' do
      get '/api/v1/health'
      expect(response).to have_http_status(:ok)
    end

    it 'returns health status information' do
      get '/api/v1/health'

      expect(response.parsed_body).to have_key('status')
      expect(response.parsed_body).to have_key('timestamp')
      expect(response.parsed_body).to have_key('version')
      expect(response.parsed_body).to have_key('environment')
      expect(response.parsed_body).to have_key('checks')
      expect(response.parsed_body['status']).to eq('healthy')
    end

    it 'includes database check' do
      get '/api/v1/health'

      expect(response.parsed_body['checks']).to have_key('database')
      expect(response.parsed_body['checks']['database']).to be_in([ true, false ])
    end

    it 'includes cache check' do
      get '/api/v1/health'

      expect(response.parsed_body['checks']).to have_key('cache')
      expect(response.parsed_body['checks']['cache']).to be_in([ true, false ])
    end

    it 'returns current environment' do
      get '/api/v1/health'

      expect(response.parsed_body['environment']).to eq('test')
    end

    context 'when database is unavailable' do
      before do
        allow(ActiveRecord::Base.connection).to receive(:active?).and_raise(StandardError)
      end

      it 'returns database as unhealthy' do
        get '/api/v1/health'

        expect(response.parsed_body['checks']['database']).to be false
      end

      it 'still returns 200 OK' do
        get '/api/v1/health'

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when cache is unavailable' do
      before do
        allow(Rails.cache).to receive(:write).and_raise(StandardError)
      end

      it 'returns cache as unhealthy' do
        get '/api/v1/health'

        expect(response.parsed_body['checks']['cache']).to be false
      end

      it 'still returns 200 OK' do
        get '/api/v1/health'

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
