require 'spec_helper'

RSpec.describe 'Routes for hydrus_items', type: :routing do
  describe 'GET /items' do
    it 'does not route' do
      expect(get('/items')).not_to be_routable
    end
  end

  describe 'POST /items' do
    it 'routes to create' do
      expect(post('/items')).to route_to('hydrus_items#create')
    end
  end

  describe 'GET /items/new' do
    it 'routes to new' do
      expect(get('/items/new')).to route_to('hydrus_items#new')
    end
  end

  describe 'POST /items/777/create_file' do
    it 'routes to create_file' do
      expect(post('/items/777/create_file')).to route_to('hydrus_items#create_file', id: '777')
    end
  end

  describe 'GET /items/777/destroy_file' do
    it 'routes to destroy_file' do
      expect(get('/items/777/destroy_file')).to route_to('hydrus_items#destroy_file', id: '777')
    end
  end

  describe 'GET /items/777/destroy_value' do
    it 'routes to destroy_value' do
      expect(get('/items/777/destroy_value')).to route_to('hydrus_items#destroy_value', id: '777')
    end
  end

  describe 'POST /items/open_new_version/777' do
    it 'routes open_new_version' do
      expect(post: '/items/open_new_version/777').to route_to('hydrus_items#open_new_version', id: '777')
    end
  end

  describe 'GET /items/777/edit' do
    it 'routes to edit' do
      expect(get('/items/777/edit')).to route_to('hydrus_items#edit', id: '777')
    end
  end

  describe 'DELETE /items/777' do
    it 'routes to destroy' do
      expect(delete('/items/777')).to route_to('hydrus_items#destroy', id: '777')
    end
  end

  describe 'GET /items/777' do
    it 'routes to show' do
      expect(get('/items/777')).to route_to('hydrus_items#show', id: '777')
    end
  end

  describe 'PATCH /items/777' do
    it 'routes to update' do
      expect(patch('/items/777')).to route_to('hydrus_items#update', id: '777')
    end
  end

  describe 'POST /items/resubmit/777' do
    it 'routes to resubmit' do
      expect(post('/items/resubmit/777')).to route_to('hydrus_items#resubmit', id: '777')
    end
  end

  describe 'POST /items/approve/777' do
    it 'routes to approve' do
      expect(post('/items/approve/777')).to route_to('hydrus_items#approve', id: '777')
    end
  end

  describe 'POST /items/disapprove/777' do
    it 'routes to disapprove' do
      expect(post('/items/disapprove/777')).to route_to('hydrus_items#disapprove', id: '777')
    end
  end

  describe 'POST /items/publish_directly/777' do
    it 'routes to publish_directly' do
      expect(post('/items/publish_directly/777')).to route_to('hydrus_items#publish_directly', id: '777')
    end
  end

  describe 'POST /items/submit_for_approval//777' do
    it 'routes to submit_for_approval' do
      expect(post('/items/submit_for_approval/777')).to route_to('hydrus_items#submit_for_approval', id: '777')
    end
  end

  describe 'POST /items/send_purl_email' do
    it 'routes to send_purl_email' do
      expect(post('/items/send_purl_email')).to route_to('hydrus_items#send_purl_email')
    end
  end

  describe 'GET /items/discard_confirmation/777' do
    it 'routes to discard_confirmation' do
      expect(get('/items/discard_confirmation/777')).to route_to('hydrus_items#discard_confirmation', id: '777')
    end
  end
end
