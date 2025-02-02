# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UserSettings::Menus::SavedRepliesMenu, feature_category: :navigation do
  it_behaves_like 'User settings menu',
    link: '/-/profile/saved_replies',
    title: _('Saved Replies'),
    icon: 'symlink',
    active_routes: { controller: :saved_replies }

  describe '#render?' do
    subject { described_class.new(context) }

    let_it_be(:user) { build(:user) }

    context 'when saved replies are enabled' do
      before do
        allow(subject).to receive(:saved_replies_enabled?).and_return(true)
      end

      context 'when user is logged in' do
        let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

        it 'does not render' do
          expect(subject.render?).to be true
        end
      end

      context 'when user is not logged in' do
        let(:context) { Sidebars::Context.new(current_user: nil, container: nil) }

        subject { described_class.new(context) }

        it 'does not render' do
          expect(subject.render?).to be false
        end
      end
    end

    context 'when saved replies are disabled' do
      before do
        allow(subject).to receive(:saved_replies_enabled?).and_return(false)
      end

      context 'when user is logged in' do
        let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

        it 'renders' do
          expect(subject.render?).to be false
        end
      end

      context 'when user is not logged in' do
        let(:context) { Sidebars::Context.new(current_user: nil, container: nil) }

        subject { described_class.new(context) }

        it 'does not render' do
          expect(subject.render?).to be false
        end
      end
    end
  end
end
