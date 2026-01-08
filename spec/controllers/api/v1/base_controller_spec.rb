require 'rails_helper'

RSpec.describe Api::V1::BaseController, type: :controller do
  # Create a test controller to access private methods
  controller(Api::V1::BaseController) do
    def test_action
      render json: { ok: true }
    end
  end

  before do
    routes.draw { get 'test_action' => 'anonymous#test_action' }
  end

  describe '#paginate' do
    let(:mock_collection) do
      double('collection',
        page: double('paged', per: [ { id: 1 }, { id: 2 } ])
      )
    end

    it 'paginates with default per_page of 25' do
      expect(mock_collection).to receive(:page).with(nil).and_return(mock_collection)
      expect(mock_collection).to receive(:per).with(25).and_return([])

      controller.send(:paginate, mock_collection)
    end
  end
end
