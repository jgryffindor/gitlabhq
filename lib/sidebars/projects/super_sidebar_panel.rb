# frozen_string_literal: true

module Sidebars
  module Projects
    class SuperSidebarPanel < ::Sidebars::Projects::Panel
      include ::Sidebars::Concerns::SuperSidebarPanel
      extend ::Gitlab::Utils::Override

      override :configure_menus
      def configure_menus
        super
        old_menus = @menus
        @menus = []

        add_menu(Sidebars::StaticMenu.new(context))
        add_menu(Sidebars::Projects::SuperSidebarMenus::PlanMenu.new(context))

        pick_from_old_menus(old_menus)

        insert_menu_before(
          Sidebars::Projects::Menus::MonitorMenu,
          Sidebars::Projects::SuperSidebarMenus::OperationsMenu.new(context)
        )

        insert_menu_before(
          Sidebars::Projects::Menus::SettingsMenu,
          Sidebars::UncategorizedMenu.new(context)
        )

        transform_old_menus(@menus, @scope_menu, *old_menus)
      end

      override :super_sidebar_context_header
      def super_sidebar_context_header
        {
          title: context.project.name,
          avatar: context.project.avatar_url,
          id: context.project.id
        }
      end
    end
  end
end
