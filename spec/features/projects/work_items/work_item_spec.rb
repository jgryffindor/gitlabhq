# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work item', :js, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:work_item) { create(:work_item, project: project) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:milestones) { create_list(:milestone, 25, project: project) }

  context 'for signed in user' do
    before do
      project.add_developer(user)

      sign_in(user)
    end

    context 'with internal id' do
      before do
        visit project_work_items_path(project, work_items_path: work_item.iid, iid_path: true)
      end

      it_behaves_like 'work items title'
      it_behaves_like 'work items status'
      it_behaves_like 'work items assignees'
      it_behaves_like 'work items labels'
      it_behaves_like 'work items comments'
      it_behaves_like 'work items description'
      it_behaves_like 'work items milestone'
    end

    context 'with global id' do
      before do
        stub_feature_flags(use_iid_in_work_items_path: false)
        visit project_work_items_path(project, work_items_path: work_item.id)
      end

      it_behaves_like 'work items status'
      it_behaves_like 'work items assignees'
      it_behaves_like 'work items labels'
      it_behaves_like 'work items comments'
      it_behaves_like 'work items description'
    end
  end

  context 'for signed in owner' do
    before do
      project.add_owner(user)

      sign_in(user)

      visit project_work_items_path(project, work_items_path: work_item.id)
    end

    it_behaves_like 'work items invite members'
  end
end
