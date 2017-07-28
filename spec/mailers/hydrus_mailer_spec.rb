require 'spec_helper'

describe HydrusMailer, type: :mailer do

  before(:each) do
    @fobj = Hydrus::Collection.new
    @fobj.title='Collection Title'
    allow(@fobj).to receive('owner').and_return('jdoe')
    allow(@fobj).to receive('object_type').and_return('collection')
  end

  describe 'open notification' do
    before(:each) do
      allow(@fobj).to receive('recipients_for_collection_update_emails').and_return('jdoe1, jdoe2')
      @mail = HydrusMailer.open_notification(object: @fobj)
    end
    it 'should have the correct subject' do
      expect(@mail.subject).to eq('Collection opened for deposit in the Stanford Digital Repository')
    end
    it 'should have the correct recipients' do
      expect(@mail.to).to include('jdoe1@stanford.edu', 'jdoe2@stanford.edu')
    end
    it 'should have the correct text in the body' do
      body = Capybara.string(@mail.body.to_s)
      expect(body).to have_content('jdoe has opened the "Collection Title" collection for deposit')
    end
  end

  describe 'close notification' do
    before(:each) do
      allow(@fobj).to receive('recipients_for_collection_update_emails').and_return('jdoe1, jdoe2')
      @mail = HydrusMailer.close_notification(object: @fobj)
    end
    it 'should have the correct subject' do
      expect(@mail.subject).to eq('Collection closed for deposit in the Stanford Digital Repository')
    end
    it 'should have the correct recipients' do
      expect(@mail.to).to include('jdoe1@stanford.edu', 'jdoe2@stanford.edu')
    end
    it 'should have the correct text in the body' do
      body = Capybara.string(@mail.body.to_s)
      expect(body).to have_content('jdoe has closed the "Collection Title" collection')
    end
  end

  describe 'invitation' do
    before(:each) do
      @mail = HydrusMailer.invitation(to: 'jdoe1, jdoe2', object: @fobj)
    end
    it 'should have the correct subject' do
      expect(@mail.subject).to eq('Invitation to deposit in the Stanford Digital Repository')
    end
    it 'should have the correct recipients' do
      expect(@mail.to).to include('jdoe1@stanford.edu', 'jdoe2@stanford.edu')
    end
    it 'should have the correct text in the body' do
      body = Capybara.string(@mail.body.to_s)
      expect(body).to have_content('jdoe has invited you to deposit into the "Collection Title" collection')
    end
  end

  describe 'object_returned' do
    before(:each) do
      allow(@fobj).to receive('recipients_for_object_returned_email').and_return('jdoe1, jdoe2')
      @mail = HydrusMailer.object_returned(object: @fobj, returned_by: 'archivist1')
    end
    it 'should have the correct subject' do
      expect(@mail.subject).to eq('Collection returned in the Stanford Digital Repository')
    end
    it 'should have the correct recipients' do
      expect(@mail.to).to include('jdoe1@stanford.edu', 'jdoe2@stanford.edu')
    end
    it 'should have the correct text in the body' do
      body = Capybara.string(@mail.body.to_s)
      expect(body).to have_content('archivist1 has returned the collection "Collection Title" in the Stanford Digital Repository.')
    end
  end

  describe 'private methods' do

    describe 'process user list' do
      it 'should turn all user strings into email addresses' do
        expect(HydrusMailer.process_user_list('jdoe1, jdoe2,jdoe3,  jdoe4 ')).to eq(['jdoe1@stanford.edu', 'jdoe2@stanford.edu', 'jdoe3@stanford.edu', 'jdoe4@stanford.edu'])
      end
      it 'should not attempt to put @stanford.edu at the end of email addresses' do
        expect(HydrusMailer.process_user_list('jdoe1, archivist1@example.com,jdoe2')).to eq(['jdoe1@stanford.edu', 'archivist1@example.com', 'jdoe2@stanford.edu'])
      end
    end

  end

end
