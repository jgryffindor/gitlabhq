import Api from '~/api';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { DELETE_PACKAGE_ERROR_MESSAGE } from '~/packages_and_registries/shared/constants';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import {
  FETCH_PACKAGES_LIST_ERROR_MESSAGE,
  DELETE_PACKAGE_SUCCESS_MESSAGE,
  DEFAULT_PAGE,
  DEFAULT_PAGE_SIZE,
  MISSING_DELETE_PATH_ERROR,
  TERRAFORM_SEARCH_TYPE,
} from '../constants';
import { getNewPaginationPage } from '../utils';
import * as types from './mutation_types';

export const setInitialState = ({ commit }, data) => commit(types.SET_INITIAL_STATE, data);
export const setLoading = ({ commit }, data) => commit(types.SET_MAIN_LOADING, data);
export const setSorting = ({ commit }, data) => commit(types.SET_SORTING, data);
export const setFilter = ({ commit }, data) => commit(types.SET_FILTER, data);

export const receivePackagesListSuccess = ({ commit }, { data, headers }) => {
  commit(types.SET_PACKAGE_LIST_SUCCESS, data);
  commit(types.SET_PAGINATION, headers);
};

export const requestPackagesList = ({ dispatch, state }, params = {}) => {
  dispatch('setLoading', true);

  const { page = DEFAULT_PAGE, per_page: perPage = DEFAULT_PAGE_SIZE } = params;
  const { sort, orderBy } = state.sorting;
  const type = state.config.forceTerraform
    ? TERRAFORM_SEARCH_TYPE
    : state.filter.find((f) => f.type === 'type');
  const name = state.filter.find((f) => f.type === FILTERED_SEARCH_TERM);
  const packageFilters = { package_type: type?.value?.data, package_name: name?.value?.data };

  const apiMethod = state.config.isGroupPage ? 'groupPackages' : 'projectPackages';

  return Api[apiMethod](state.config.resourceId, {
    params: { page, per_page: perPage, sort, order_by: orderBy, ...packageFilters },
  })
    .then(({ data, headers }) => {
      dispatch('receivePackagesListSuccess', { data, headers });
    })
    .catch(() => {
      createAlert({
        message: FETCH_PACKAGES_LIST_ERROR_MESSAGE,
      });
    })
    .finally(() => {
      dispatch('setLoading', false);
    });
};

export const requestDeletePackage = ({ dispatch, state }, { _links }) => {
  if (!_links || !_links.delete_api_path) {
    createAlert({
      message: DELETE_PACKAGE_ERROR_MESSAGE,
    });
    const error = new Error(MISSING_DELETE_PATH_ERROR);
    return Promise.reject(error);
  }

  dispatch('setLoading', true);
  return axios
    .delete(_links.delete_api_path)
    .then(() => {
      const { page: currentPage, perPage, total } = state.pagination;
      const page = getNewPaginationPage(currentPage, perPage, total - 1);

      dispatch('requestPackagesList', { page });
      createAlert({
        message: DELETE_PACKAGE_SUCCESS_MESSAGE,
        variant: VARIANT_SUCCESS,
      });
    })
    .catch(() => {
      dispatch('setLoading', false);
      createAlert({
        message: DELETE_PACKAGE_ERROR_MESSAGE,
      });
    });
};
