# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ErrorTracking::ProjectSettings, feature_category: :error_tracking do
  let_it_be(:user) { create(:user) }

  let(:setting) { create(:project_error_tracking_setting) }
  let(:project) { setting.project }

  shared_examples 'returns project settings' do
    it 'returns correct project settings' do
      make_request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq(
        'active' => setting.reload.enabled,
        'project_name' => setting.project_name,
        'sentry_external_url' => setting.sentry_external_url,
        'api_url' => setting.api_url,
        'integrated' => setting.integrated
      )
    end
  end

  shared_examples 'returns project settings with false for integrated' do
    specify do
      make_request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq(
        'active' => setting.reload.enabled,
        'project_name' => setting.project_name,
        'sentry_external_url' => setting.sentry_external_url,
        'api_url' => setting.api_url,
        'integrated' => false
      )
    end
  end

  shared_examples 'returns no project settings' do
    it 'returns no project settings' do
      make_request

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message'])
        .to eq('404 Error Tracking Setting Not Found')
    end
  end

  shared_examples 'returns 400' do
    it 'rejects request' do
      make_request

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  shared_examples 'returns 401' do
    it 'rejects request' do
      make_request

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  shared_examples 'returns 403' do
    it 'rejects request' do
      make_request

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  shared_examples 'returns 404' do
    it 'rejects request' do
      make_request

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'returns 400 with `integrated` param required or invalid' do |error|
    it 'returns 400' do
      make_request

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error'])
        .to eq(error)
    end
  end

  shared_examples "returns error from UpdateService" do
    it "returns errors" do
      make_request

      expect(json_response['http_status']).to eq('forbidden')
      expect(json_response['message']).to eq('An error occurred')
    end
  end

  describe "PATCH /projects/:id/error_tracking/settings" do
    let(:params) { { active: false } }

    def make_request
      patch api("/projects/#{project.id}/error_tracking/settings", user), params: params
    end

    context 'when authenticated as maintainer' do
      before do
        project.add_maintainer(user)
      end

      context 'patch settings' do
        context 'integrated_error_tracking feature enabled' do
          it_behaves_like 'returns project settings'
        end

        context 'integrated_error_tracking feature disabled' do
          before do
            stub_feature_flags(integrated_error_tracking: false)
          end

          it_behaves_like 'returns project settings with false for integrated'
        end

        it 'updates enabled flag' do
          expect(setting).to be_enabled

          make_request

          expect(json_response).to include('active' => false)
          expect(setting.reload).not_to be_enabled
        end

        context 'active is invalid' do
          let(:params) { { active: "randomstring" } }

          it 'returns active is invalid if non boolean' do
            make_request

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['error'])
              .to eq('active is invalid')
          end
        end

        context 'active is empty' do
          let(:params) { { active: '' } }

          it 'returns 400' do
            make_request

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['error'])
              .to eq('active is empty')
          end
        end

        context 'with integrated param' do
          let(:params) { { active: true, integrated: true } }

          context 'integrated_error_tracking feature enabled' do
            before do
              stub_feature_flags(integrated_error_tracking: true)
            end

            it 'updates the integrated flag' do
              expect(setting.integrated).to be_falsey

              make_request

              expect(json_response).to include('integrated' => true)
              expect(setting.reload.integrated).to be_truthy
            end
          end
        end
      end

      context 'without a project setting' do
        let_it_be(:project) { create(:project) }

        before do
          project.add_maintainer(user)
        end

        context 'patch settings' do
          it_behaves_like 'returns no project settings'
        end
      end

      context "when ::Projects::Operations::UpdateService responds with an error" do
        before do
          allow_next_instance_of(::Projects::Operations::UpdateService) do |service|
            allow(service)
              .to receive(:execute)
              .and_return({ status: :error, message: 'An error occurred', http_status: :forbidden })
          end
        end

        context "when integrated" do
          let(:integrated) { true }

          it_behaves_like 'returns error from UpdateService'
        end

        context "without integrated" do
          it_behaves_like 'returns error from UpdateService'
        end
      end
    end

    context 'when authenticated as reporter' do
      before do
        project.add_reporter(user)
      end

      context 'patch request' do
        it_behaves_like 'returns 403'
      end
    end

    context 'when authenticated as developer' do
      before do
        project.add_developer(user)
      end

      context 'patch request' do
        it_behaves_like 'returns 403'
      end
    end

    context 'when authenticated as non-member' do
      context 'patch request' do
        it_behaves_like 'returns 404'
      end
    end

    context 'when unauthenticated' do
      let(:user) { nil }

      context 'patch request' do
        it_behaves_like 'returns 401'
      end
    end
  end

  describe "GET /projects/:id/error_tracking/settings" do
    def make_request
      get api("/projects/#{project.id}/error_tracking/settings", user)
    end

    context 'when authenticated as maintainer' do
      before do
        project.add_maintainer(user)
      end

      context 'get settings' do
        context 'integrated_error_tracking feature enabled' do
          before do
            stub_feature_flags(integrated_error_tracking: true)
          end

          it_behaves_like 'returns project settings'
        end

        context 'integrated_error_tracking feature disabled' do
          before do
            stub_feature_flags(integrated_error_tracking: false)
          end

          it_behaves_like 'returns project settings with false for integrated'
        end
      end
    end

    context 'without a project setting' do
      let(:project) { create(:project) }

      before do
        project.add_maintainer(user)
      end

      context 'get settings' do
        it_behaves_like 'returns no project settings'
      end
    end

    context 'when authenticated as reporter' do
      before do
        project.add_reporter(user)
      end

      it_behaves_like 'returns 403'
    end

    context 'when authenticated as developer' do
      before do
        project.add_developer(user)
      end

      it_behaves_like 'returns 403'
    end

    context 'when authenticated as non-member' do
      it_behaves_like 'returns 404'
    end

    context 'when unauthenticated' do
      let(:user) { nil }

      it_behaves_like 'returns 401'
    end
  end

  describe "PUT /projects/:id/error_tracking/settings" do
    let(:params) { { active: active, integrated: integrated } }
    let(:active) { true }
    let(:integrated) { true }

    def make_request
      put api("/projects/#{project.id}/error_tracking/settings", user), params: params
    end

    context 'when authenticated' do
      context 'as maintainer' do
        before do
          project.add_maintainer(user)
        end

        context "when integrated" do
          let(:integrated) { true }

          context "with existing setting" do
            let(:setting) { create(:project_error_tracking_setting, :integrated) }
            let(:active) { false }

            it "updates a setting" do
              expect { make_request }.not_to change { ErrorTracking::ProjectErrorTrackingSetting.count }

              expect(response).to have_gitlab_http_status(:ok)

              expect(json_response).to eq(
                "active" => false,
                "api_url" => nil,
                "integrated" => integrated,
                "project_name" => nil,
                "sentry_external_url" => nil
              )
            end
          end

          context "without setting" do
            let(:active) { true }
            let_it_be(:project) { create(:project) }

            it "creates a setting" do
              expect { make_request }.to change { ErrorTracking::ProjectErrorTrackingSetting.count }

              expect(response).to have_gitlab_http_status(:ok)

              expect(json_response).to eq(
                "active" => true,
                "api_url" => nil,
                "integrated" => integrated,
                "project_name" => nil,
                "sentry_external_url" => nil
              )
            end
          end

          context "when ::Projects::Operations::UpdateService responds with an error" do
            before do
              allow_next_instance_of(::Projects::Operations::UpdateService) do |service|
                allow(service)
                  .to receive(:execute)
                        .and_return({ status: :error, message: 'An error occurred', http_status: :forbidden })
              end
            end

            it_behaves_like 'returns error from UpdateService'
          end
        end

        context "integrated_error_tracking feature disabled" do
          let(:integrated) { true }

          before do
            stub_feature_flags(integrated_error_tracking: false)
          end

          it_behaves_like 'returns 404'
        end

        context "when integrated param is invalid" do
          let(:params) { { active: active, integrated: 'invalid_string' } }

          it_behaves_like 'returns 400 with `integrated` param required or invalid', 'integrated is invalid'
        end

        context "when integrated param is missing" do
          let(:params) { { active: active } }

          it_behaves_like 'returns 400 with `integrated` param required or invalid', 'integrated is missing'
        end
      end

      context 'as reporter' do
        before do
          project.add_reporter(user)
        end

        it_behaves_like 'returns 403'
      end

      context "as developer" do
        before do
          project.add_developer(user)
        end

        it_behaves_like 'returns 403'
      end

      context 'as non-member' do
        it_behaves_like 'returns 404'
      end
    end

    context "when unauthorized" do
      let(:user) { nil }
      let(:integrated) { true }

      it_behaves_like 'returns 401'
    end
  end
end
