// Note: all constants defined here are considered internal implementation
// details for the sidebar. They should not be imported by anything outside of
// the super_sidebar directory.

import Vue from 'vue';

export const SIDEBAR_PORTAL_ID = 'sidebar-portal-mount';

export const portalState = Vue.observable({
  ready: false,
});

export const MAX_FREQUENT_PROJECTS_COUNT = 5;
export const MAX_FREQUENT_GROUPS_COUNT = 3;
