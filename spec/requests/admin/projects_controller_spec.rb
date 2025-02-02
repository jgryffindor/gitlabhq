# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ProjectsController, :enable_admin_mode, feature_category: :projects do
  let_it_be(:project) { create(:project, :public, name: 'test', description: 'test') }
  let_it_be(:admin) { create(:admin) }

  describe 'PUT #update' do
    let(:project_params) { {} }
    let(:params) { { project: project_params } }
    let(:path_params) { { namespace_id: project.namespace.to_param, id: project.to_param } }

    before do
      sign_in(admin)
    end

    subject do
      put admin_namespace_project_path(path_params), params: params
    end

    context 'when changing the name' do
      let(:project_params) { { name: 'new name' } }

      it 'returns success' do
        subject

        expect(response).to have_gitlab_http_status(:found)
      end

      it 'changes the name' do
        expect { subject }.to change { project.reload.name }.to('new name')
      end
    end

    context 'when changing the description' do
      let(:project_params) { { description: 'new description' } }

      it 'returns success' do
        subject

        expect(response).to have_gitlab_http_status(:found)
      end

      it 'changes the project description' do
        expect { subject }.to change { project.reload.description }.to('new description')
      end
    end

    context 'when changing the name to an invalid name' do
      let(:project_params) { { name: 'invalid/project/name' } }

      it 'does not change the name' do
        expect { subject }.not_to change { project.reload.name }
      end
    end
  end
end
