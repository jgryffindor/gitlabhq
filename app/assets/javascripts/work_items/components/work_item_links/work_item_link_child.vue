<script>
import { GlButton, GlLink, GlIcon, GlTooltipDirective } from '@gitlab/ui';

import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import RichTimestampTooltip from '~/vue_shared/components/rich_timestamp_tooltip.vue';
import WorkItemLinkChildMetadata from 'ee_else_ce/work_items/components/work_item_links/work_item_link_child_metadata.vue';

import {
  STATE_OPEN,
  TASK_TYPE_NAME,
  WORK_ITEM_TYPE_VALUE_OBJECTIVE,
  WIDGET_TYPE_PROGRESS,
  WIDGET_TYPE_HEALTH_STATUS,
  WIDGET_TYPE_MILESTONE,
  WIDGET_TYPE_HIERARCHY,
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_LABELS,
  WORK_ITEM_NAME_TO_ICON_MAP,
} from '../../constants';
import getWorkItemTreeQuery from '../../graphql/work_item_tree.query.graphql';
import WorkItemLinksMenu from './work_item_links_menu.vue';
import WorkItemTreeChildren from './work_item_tree_children.vue';

export default {
  components: {
    GlLink,
    GlButton,
    GlIcon,
    RichTimestampTooltip,
    WorkItemLinkChildMetadata,
    WorkItemLinksMenu,
    WorkItemTreeChildren,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    canUpdate: {
      type: Boolean,
      required: true,
    },
    issuableGid: {
      type: String,
      required: true,
    },
    childItem: {
      type: Object,
      required: true,
    },
    hasIndirectChildren: {
      type: Boolean,
      required: false,
      default: true,
    },
    workItemType: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isExpanded: false,
      children: [],
      isLoadingChildren: false,
    };
  },
  computed: {
    canHaveChildren() {
      return this.workItemType === WORK_ITEM_TYPE_VALUE_OBJECTIVE;
    },
    metadataWidgets() {
      return this.childItem.widgets?.reduce((metadataWidgets, widget) => {
        // Skip Hierarchy widget as it is not part of metadata.
        if (widget.type && widget.type !== WIDGET_TYPE_HIERARCHY) {
          // eslint-disable-next-line no-param-reassign
          metadataWidgets[widget.type] = widget;
        }
        return metadataWidgets;
      }, {});
    },
    isItemOpen() {
      return this.childItem.state === STATE_OPEN;
    },
    childItemType() {
      return this.childItem.workItemType.name;
    },
    iconName() {
      if (this.childItemType === TASK_TYPE_NAME) {
        return this.isItemOpen ? 'issue-open-m' : 'issue-close';
      }
      return WORK_ITEM_NAME_TO_ICON_MAP[this.childItemType];
    },
    iconClass() {
      if (this.childItemType === TASK_TYPE_NAME) {
        return this.isItemOpen ? 'gl-text-green-500' : 'gl-text-blue-500';
      }
      return '';
    },
    stateTimestamp() {
      return this.isItemOpen ? this.childItem.createdAt : this.childItem.closedAt;
    },
    stateTimestampTypeText() {
      return this.isItemOpen ? __('Created') : __('Closed');
    },
    childPath() {
      return `${gon?.relative_url_root || ''}/${this.projectPath}/-/work_items/${
        this.childItem.iid
      }?iid_path=true`;
    },
    hasChildren() {
      return this.getWidgetByType(this.childItem, WIDGET_TYPE_HIERARCHY)?.hasChildren;
    },
    chevronType() {
      return this.isExpanded ? 'chevron-down' : 'chevron-right';
    },
    chevronTooltip() {
      return this.isExpanded ? __('Collapse') : __('Expand');
    },
    hasMetadata() {
      if (this.metadataWidgets) {
        return (
          Number.isInteger(this.metadataWidgets[WIDGET_TYPE_PROGRESS]?.progress) ||
          Boolean(this.metadataWidgets[WIDGET_TYPE_HEALTH_STATUS]?.healthStatus) ||
          Boolean(this.metadataWidgets[WIDGET_TYPE_MILESTONE]?.milestone) ||
          this.metadataWidgets[WIDGET_TYPE_ASSIGNEES]?.assignees?.nodes.length > 0 ||
          this.metadataWidgets[WIDGET_TYPE_LABELS]?.labels?.nodes.length > 0
        );
      }
      return false;
    },
  },
  methods: {
    toggleItem() {
      this.isExpanded = !this.isExpanded;
      if (this.children.length === 0 && this.hasChildren) {
        this.fetchChildren();
      }
    },
    getWidgetByType(workItem, widgetType) {
      return workItem?.widgets?.find((widget) => widget.type === widgetType);
    },
    async fetchChildren() {
      this.isLoadingChildren = true;
      try {
        const { data } = await this.$apollo.query({
          query: getWorkItemTreeQuery,
          variables: {
            id: this.childItem.id,
          },
        });
        this.children = this.getWidgetByType(data?.workItem, WIDGET_TYPE_HIERARCHY).children.nodes;
      } catch (error) {
        this.isExpanded = !this.isExpanded;
        createAlert({
          message: s__('Hierarchy|Something went wrong while fetching children.'),
          captureError: true,
          error,
        });
      } finally {
        this.isLoadingChildren = false;
      }
    },
  },
};
</script>

<template>
  <div>
    <div
      class="gl-display-flex gl-align-items-flex-start"
      :class="{ 'gl-ml-6': canHaveChildren && !hasChildren && hasIndirectChildren }"
    >
      <gl-button
        v-if="hasChildren"
        v-gl-tooltip.viewport
        :title="chevronTooltip"
        :aria-label="chevronTooltip"
        :icon="chevronType"
        category="tertiary"
        size="small"
        :loading="isLoadingChildren"
        class="gl-px-0! gl-py-3! gl-mr-3"
        data-testid="expand-child"
        @click="toggleItem"
      />
      <div
        class="work-item-link-child gl-relative gl-display-flex gl-flex-grow-1 gl-overflow-break-word gl-min-w-0 gl-pl-3 gl-pr-2 gl-rounded-base"
        :class="[hasMetadata ? 'gl-py-3' : 'gl-py-0']"
        data-testid="links-child"
      >
        <span
          :id="`stateIcon-${childItem.id}`"
          class="gl-cursor-help gl-mr-3 gl-line-height-32"
          :class="{ 'gl-display-flex': hasMetadata }"
          data-testid="item-status-icon"
        >
          <gl-icon
            class="gl-text-secondary"
            :class="iconClass"
            :name="iconName"
            :aria-label="stateTimestampTypeText"
          />
        </span>
        <div
          class="gl-display-flex gl-flex-grow-1"
          :class="{
            'gl-flex-direction-column gl-align-items-flex-start': hasMetadata,
            'gl-align-items-center': !hasMetadata,
          }"
        >
          <div class="gl-display-flex">
            <rich-timestamp-tooltip
              :target="`stateIcon-${childItem.id}`"
              :raw-timestamp="stateTimestamp"
              :timestamp-type-text="stateTimestampTypeText"
            />
            <gl-icon
              v-if="childItem.confidential"
              v-gl-tooltip.top
              name="eye-slash"
              class="gl-mr-2 gl-text-orange-500"
              data-testid="confidential-icon"
              :aria-label="__('Confidential')"
              :title="__('Confidential')"
            />
            <gl-link
              :href="childPath"
              class="gl-overflow-wrap-break gl-line-height-normal gl-text-black-normal! gl-font-weight-bold"
              data-testid="item-title"
              @click="$emit('click', $event)"
              @mouseover="$emit('mouseover')"
              @mouseout="$emit('mouseout')"
            >
              {{ childItem.title }}
            </gl-link>
          </div>
          <work-item-link-child-metadata
            v-if="hasMetadata"
            :metadata-widgets="metadataWidgets"
            class="gl-mt-1"
          />
        </div>
        <div
          v-if="canUpdate"
          class="gl-ml-0 gl-sm-ml-auto! gl-display-inline-flex gl-align-items-center"
        >
          <work-item-links-menu
            :work-item-id="childItem.id"
            :parent-work-item-id="issuableGid"
            data-testid="links-menu"
            @removeChild="$emit('removeChild', childItem.id)"
          />
        </div>
      </div>
    </div>
    <work-item-tree-children
      v-if="isExpanded"
      :project-path="projectPath"
      :can-update="canUpdate"
      :work-item-id="issuableGid"
      :work-item-type="workItemType"
      :children="children"
      @removeChild="fetchChildren"
      @click="$emit('click', $event)"
    />
  </div>
</template>
