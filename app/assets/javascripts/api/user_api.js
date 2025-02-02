import { DEFAULT_PER_PAGE } from '~/api';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import axios from '../lib/utils/axios_utils';
import { buildApiUrl } from './api_utils';

const USER_COUNTS_PATH = '/api/:version/user_counts';
const USERS_PATH = '/api/:version/users.json';
const USER_PATH = '/api/:version/users/:id';
const USER_STATUS_PATH = '/api/:version/users/:id/status';
const USER_PROJECTS_PATH = '/api/:version/users/:id/projects';
const USER_POST_STATUS_PATH = '/api/:version/user/status';
const USER_FOLLOW_PATH = '/api/:version/users/:id/follow';
const USER_UNFOLLOW_PATH = '/api/:version/users/:id/unfollow';
const USER_ASSOCIATIONS_COUNT_PATH = '/api/:version/users/:id/associations_count';

export function getUsers(query, options) {
  const url = buildApiUrl(USERS_PATH);
  return axios.get(url, {
    params: {
      search: query,
      per_page: DEFAULT_PER_PAGE,
      ...options,
    },
  });
}

export function getUser(id, options) {
  const url = buildApiUrl(USER_PATH).replace(':id', encodeURIComponent(id));
  return axios.get(url, {
    params: options,
  });
}

export function getUserCounts() {
  const url = buildApiUrl(USER_COUNTS_PATH);
  return axios.get(url);
}

export function getUserStatus(id, options) {
  const url = buildApiUrl(USER_STATUS_PATH).replace(':id', encodeURIComponent(id));
  return axios.get(url, {
    params: options,
  });
}

export function getUserProjects(userId, query, options, callback) {
  const url = buildApiUrl(USER_PROJECTS_PATH).replace(':id', userId);
  const defaults = {
    search: query,
    per_page: DEFAULT_PER_PAGE,
  };
  return axios
    .get(url, {
      params: { ...defaults, ...options },
    })
    .then(({ data }) => callback(data))
    .catch(() =>
      createAlert({
        message: __('Something went wrong while fetching projects'),
      }),
    );
}

export function updateUserStatus({ emoji, message, availability, clearStatusAfter }) {
  const url = buildApiUrl(USER_POST_STATUS_PATH);

  return axios.patch(url, {
    emoji,
    message,
    availability,
    clear_status_after: clearStatusAfter,
  });
}

export function followUser(userId) {
  const url = buildApiUrl(USER_FOLLOW_PATH).replace(':id', encodeURIComponent(userId));
  return axios.post(url);
}

export function unfollowUser(userId) {
  const url = buildApiUrl(USER_UNFOLLOW_PATH).replace(':id', encodeURIComponent(userId));
  return axios.post(url);
}

export function associationsCount(userId) {
  const url = buildApiUrl(USER_ASSOCIATIONS_COUNT_PATH).replace(':id', encodeURIComponent(userId));
  return axios.get(url);
}
