import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { parseBoolean } from '~/lib/utils/common_utils';
import Translate from '~/vue_shared/translate';
import createDefaultClient from '~/lib/graphql';
import ImportProjectsTable from './components/import_projects_table.vue';

import createStore from './store';

Vue.use(Translate);
Vue.use(VueApollo);

export function initStoreFromElement(element) {
  const {
    ciCdOnly,
    canSelectNamespace,
    provider,

    reposPath,
    jobsPath,
    importPath,
    cancelPath,
    defaultTargetNamespace,
    paginatable,
  } = element.dataset;

  return createStore({
    initialState: {
      defaultTargetNamespace,
      ciCdOnly: parseBoolean(ciCdOnly),
      canSelectNamespace: parseBoolean(canSelectNamespace),
      provider,
    },
    endpoints: {
      reposPath,
      jobsPath,
      importPath,
      cancelPath,
    },
    hasPagination: parseBoolean(paginatable),
  });
}

export function initPropsFromElement(element) {
  return {
    providerTitle: element.dataset.providerTitle,
    filterable: parseBoolean(element.dataset.filterable),
    paginatable: parseBoolean(element.dataset.paginatable),
    optionalStages: JSON.parse(element.dataset.optionalStages),
    cancelable: Boolean(element.dataset.cancelPath),
  };
}

const defaultClient = createDefaultClient();

const apolloProvider = new VueApollo({
  defaultClient,
});

export default function mountImportProjectsTable({
  mountElement,
  Component = ImportProjectsTable,
  extraProps = () => ({}),
}) {
  if (!mountElement) return undefined;

  const store = initStoreFromElement(mountElement);
  const props = initPropsFromElement(mountElement);

  return new Vue({
    el: mountElement,
    name: 'ImportProjectsRoot',
    store,
    apolloProvider,
    render(createElement) {
      // We are using attrs instead of props so root-level component with inheritAttrs
      // will be able to pass them down
      return createElement(Component, { attrs: { ...props, ...extraProps(mountElement.dataset) } });
    },
  });
}
