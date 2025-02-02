# frozen_string_literal: true

module QA
  RSpec.describe 'Verify' do
    describe 'Pipeline with prefill variables', product_group: :pipeline_security do
      let(:prefill_variable_description1) { Faker::Lorem.sentence }
      let(:prefill_variable_value1) { Faker::Lorem.word }
      let(:prefill_variable_value5) { Faker::Lorem.word }
      let(:prefill_variable_description2) { Faker::Lorem.sentence }
      let(:prefill_variable_description5) { Faker::Lorem.sentence }
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-prefill-variables'
        end
      end

      let!(:commit) do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files(
            [
              {
                file_path: '.gitlab-ci.yml',
                content: <<~YAML
                  variables:
                    TEST1:
                      value: #{prefill_variable_value1}
                      description: #{prefill_variable_description1}
                    TEST2:
                      description: #{prefill_variable_description2}
                    TEST3:
                      value: test 3 value
                    TEST4: test 4 value
                    TEST5:
                      value: "FOO"
                      options:
                        - #{prefill_variable_value5}
                        - "FOO"
                      description: #{prefill_variable_description5}
                  test:
                    script: echo "$FOO"
                YAML
              }
            ]
          )
        end
      end

      before do
        Flow::Login.sign_in
        project.visit!

        # Navigate to Run Pipeline page
        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform(&:click_run_pipeline_button)
      end

      it 'shows only variables with description as prefill variables on the run pipeline page',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/378977' do
        Page::Project::Pipeline::New.perform do |new|
          aggregate_failures do
            expect(new).to have_field('Input variable key', with: 'TEST1')
            expect(new).to have_field('Input variable value', with: prefill_variable_value1)
            expect(new).to have_content(prefill_variable_description1)

            expect(new).to have_field('Input variable key', with: 'TEST2')
            expect(new).to have_field('Input variable value', with: '')
            expect(new).to have_content(prefill_variable_description2)

            expect(new).not_to have_field('Input variable key', with: 'TEST3')
            expect(new).not_to have_field('Input variable key', with: 'TEST4')

            expect(new).to have_field('Input variable key', with: 'TEST5')
            expect(new).to have_content(prefill_variable_description5)
          end
        end
      end

      it 'shows dropdown for variables with description, value, and options defined',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/383820' do
        Page::Project::Pipeline::New.perform do |new|
          aggregate_failures do
            expect(new.variable_dropdown).to have_text('FOO')

            new.click_variable_dropdown

            expect(new.variable_dropdown_item_with_index(0)).to have_text(prefill_variable_value5)
            expect(new.variable_dropdown_item_with_index(1)).to have_text('FOO')
          end
        end
      end
    end
  end
end
