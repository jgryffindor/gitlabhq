# frozen_string_literal: true

# TODO: remove this test when 'vscode_web_ide' feature flag is default enabled
module QA
  RSpec.describe 'Create', :skip_live_env, except: { job: 'review-qa-*' }, product_group: :editor do
    describe 'Git Server Hooks' do
      let(:file_path) { File.join(Runtime::Path.fixtures_path, 'web_ide', 'README.md') }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          # Projects that have names that include pattern 'reject-prereceive' trigger a server hook on orchestrated env
          # that returns an error string using GL-HOOK-ERR
          project.name = "project-reject-prereceive-#{SecureRandom.hex(8)}"
        end
      end

      before do
        Flow::Login.sign_in
        project.visit!
      end

      context 'with custom error messages' do
        it 'renders preconfigured error message when user hook failed on commit in WebIDE',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/364751' do
          Page::Project::Show.perform(&:open_web_ide_via_shortcut)
          Page::Project::WebIDE::Edit.perform do |ide|
            ide.wait_until_ide_loads
            ide.upload_file(file_path)
            ide.commit_changes(wait_for_success: false)
            expect(ide).to have_text('Custom error message rejecting prereceive hook for projects with GL_PROJECT_PATH')
          end
        end
      end
    end
  end
end
