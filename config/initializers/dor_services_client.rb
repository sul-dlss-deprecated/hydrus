# frozen_string_literal: true

# Configure dor-services-client to use the dor-services URL
Dor::Services::Client.configure(url: Settings.dor_services.url,
                                username: Settings.dor_services.user,
                                password: Settings.dor_services.pass)
