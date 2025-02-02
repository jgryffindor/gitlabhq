# frozen_string_literal: true

module QA
  module Page
    module Profile
      class Menu < Page::Base
        # We need to check remote_mobile_device_name instead of mobile_layout? here
        # since tablets have the regular top navigation bar but still close the left nav
        prepend QA::Mobile::Page::SubMenus::Common if QA::Runtime::Env.remote_mobile_device_name

        view 'lib/sidebars/user_settings/menus/access_tokens_menu.rb' do
          element :access_token_link
        end

        view 'lib/sidebars/user_settings/menus/ssh_keys_menu.rb' do
          element :ssh_keys_link
        end

        view 'lib/sidebars/user_settings/menus/emails_menu.rb' do
          element :profile_emails_link
        end

        view 'lib/sidebars/user_settings/menus/password_menu.rb' do
          element :profile_password_link
        end

        view 'lib/sidebars/user_settings/menus/account_menu.rb' do
          element :profile_account_link
        end

        def click_access_tokens
          within_sidebar do
            click_element(:access_token_link)
          end
        end

        def click_ssh_keys
          within_sidebar do
            click_element(:ssh_keys_link)
          end
        end

        def click_account
          within_sidebar do
            click_element(:profile_account_link)
          end
        end

        def click_emails
          within_sidebar do
            click_element(:profile_emails_link)
          end
        end

        def click_password
          within_sidebar do
            click_element(:profile_password_link)
          end
        end

        private

        def within_sidebar
          page.within('.sidebar-top-level-items') do
            yield
          end
        end
      end
    end
  end
end

QA::Page::Profile::Menu.prepend_mod_with('Page::Profile::Menu', namespace: QA)
