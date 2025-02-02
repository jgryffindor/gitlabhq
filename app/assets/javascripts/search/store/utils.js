import { isEqual, orderBy } from 'lodash';
import AccessorUtilities from '~/lib/utils/accessor';
import { formatNumber } from '~/locale';
import { joinPaths } from '~/lib/utils/url_utility';
import { languageFilterData } from '~/search/sidebar/constants/language_filter_data';
import {
  MAX_FREQUENT_ITEMS,
  MAX_FREQUENCY,
  SIDEBAR_PARAMS,
  NUMBER_FORMATING_OPTIONS,
} from './constants';

const LANGUAGE_AGGREGATION_NAME = languageFilterData.filterParam;

function extractKeys(object, keyList) {
  return Object.fromEntries(keyList.map((key) => [key, object[key]]));
}

export const loadDataFromLS = (key) => {
  if (!AccessorUtilities.canUseLocalStorage()) {
    return [];
  }

  try {
    return JSON.parse(localStorage.getItem(key)) || [];
  } catch {
    // The LS got in a bad state, let's wipe it
    localStorage.removeItem(key);
    return [];
  }
};

export const setFrequentItemToLS = (key, data, itemData) => {
  if (!AccessorUtilities.canUseLocalStorage()) {
    return [];
  }

  const keyList = [
    'id',
    'avatar_url',
    'name',
    'full_name',
    'name_with_namespace',
    'frequency',
    'lastUsed',
  ];

  try {
    const frequentItems = data[key].map((obj) => extractKeys(obj, keyList));
    const item = extractKeys(itemData, keyList);
    const existingItemIndex = frequentItems.findIndex((i) => i.id === item.id);

    if (existingItemIndex >= 0) {
      // Up the frequency (Max 5)
      const currentFrequency = frequentItems[existingItemIndex].frequency;
      frequentItems[existingItemIndex].frequency = Math.min(currentFrequency + 1, MAX_FREQUENCY);
      frequentItems[existingItemIndex].lastUsed = new Date().getTime();
    } else {
      // Only store a max of 5 items
      if (frequentItems.length >= MAX_FREQUENT_ITEMS) {
        frequentItems.pop();
      }

      frequentItems.push({ ...item, frequency: 1, lastUsed: new Date().getTime() });
    }

    // Sort by frequency and lastUsed
    frequentItems.sort((a, b) => {
      if (a.frequency > b.frequency) {
        return -1;
      } else if (a.frequency < b.frequency) {
        return 1;
      }
      return b.lastUsed - a.lastUsed;
    });

    // Note we do not need to commit a mutation here as immediately after this we refresh the page to
    // update the search results.
    localStorage.setItem(key, JSON.stringify(frequentItems));
    return frequentItems;
  } catch {
    // The LS got in a bad state, let's wipe it
    localStorage.removeItem(key);
    return [];
  }
};

export const mergeById = (inflatedData, storedData) => {
  return inflatedData.map((data) => {
    const stored = storedData?.find((d) => d.id === data.id) || {};
    return { ...stored, ...data };
  });
};

export const isSidebarDirty = (currentQuery, urlQuery) => {
  return SIDEBAR_PARAMS.some((param) => {
    // userAddParam ensures we don't get a false dirty from null !== undefined
    const userAddedParam = !urlQuery[param] && currentQuery[param];
    const userChangedExistingParam = urlQuery[param] && urlQuery[param] !== currentQuery[param];

    if (Array.isArray(currentQuery[param]) || Array.isArray(urlQuery[param])) {
      return !isEqual(currentQuery[param], urlQuery[param]);
    }

    return userAddedParam || userChangedExistingParam;
  });
};

export const formatSearchResultCount = (count) => {
  if (!count) {
    return '0';
  }

  const countNumber = typeof count === 'string' ? parseInt(count.replace(/,/g, ''), 10) : count;
  return formatNumber(countNumber, NUMBER_FORMATING_OPTIONS);
};

export const getAggregationsUrl = () => {
  const currentUrl = new URL(window.location.href);
  currentUrl.pathname = joinPaths('/search', 'aggregations');
  return currentUrl.toString();
};

const sortLanguages = (state, entries) => {
  const queriedLanguages = state.query?.[LANGUAGE_AGGREGATION_NAME] || [];

  if (!Array.isArray(queriedLanguages) || !queriedLanguages.length) {
    return entries;
  }

  const queriedLanguagesSet = new Set(queriedLanguages);

  return orderBy(entries, [({ key }) => queriedLanguagesSet.has(key), 'count'], ['desc', 'desc']);
};

export const prepareSearchAggregations = (state, aggregationData) =>
  aggregationData.map((item) => {
    if (item?.name === LANGUAGE_AGGREGATION_NAME) {
      return {
        ...item,
        buckets: sortLanguages(state, item.buckets),
      };
    }

    return item;
  });
