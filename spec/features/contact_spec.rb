require 'spec_helper'

describe('Contact page', type: :request, integration: true) do
  let(:archivist3) { create :archivist3 }
  before(:each) do
    @name_textbox      = 'input#name'
    @email_textbox     = 'input#email'
    @select_menu       = 'select#subject'
    @message_textarea  = 'textarea#message'
    @message           = 'Hello, this is is cool.'
    @send_button_text  = 'Send'
    HydrusMailer.stub_chain(:contact_message, :deliver_now)
  end

  it 'shows the full form and then generate an email when a user fills in the contact form when not logged in' do
    sign_out
    visit contact_path
    expect(page).to have_selector(@name_textbox)
    expect(page).to have_selector(@email_textbox)
    expect(page).to have_selector(@select_menu)
    expect(page).to have_selector(@message_textarea)
    fill_in 'email', with: 'test@test.com'
    fill_in 'message', with: @message
    click_button @send_button_text
    expect(page).to have_content 'Your message has been sent.'
    expect(HydrusMailer).to have_received(:contact_message)
  end

  it 'shows an error message if the user does not enter a message to send' do
    visit contact_path
    click_button @send_button_text
    expect(page).to have_content 'Please enter message text.'
    expect(HydrusMailer).not_to have_received(:contact_message)
  end

  it 'shows the partial form and then generate an email when a user fills in the contact form when logged in' do
    sign_in(archivist3)
    visit contact_path
    expect(page).to_not have_selector(@name_textbox) # name and email text boxes are not shown when logged in
    expect(page).to_not have_selector(@email_textbox)
    expect(page).to have_selector(@select_menu)
    expect(page).to have_selector(@message_textarea)
    fill_in 'message', with: @message
    click_button @send_button_text
    expect(page).to have_content 'Your message has been sent.'
    expect(HydrusMailer).to have_received(:contact_message)
  end
end
