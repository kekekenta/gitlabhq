import Vuex from 'vuex';
import AxiosMockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import functionsComponent from '~/serverless/components/functions.vue';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { createStore } from '~/serverless/store';
import { mockServerlessFunctions } from '../mock_data';

describe('functionsComponent', () => {
  let component;
  let store;
  let localVue;

  beforeEach(() => {
    localVue = createLocalVue();
    localVue.use(Vuex);

    store = createStore();
  });

  afterEach(() => {
    component.vm.$destroy();
  });

  it('should render empty state when Knative is not installed', () => {
    component = shallowMount(functionsComponent, {
      localVue,
      store,
      propsData: {
        installed: false,
        clustersPath: '',
        helpPath: '',
        statusPath: '',
      },
      sync: false,
    });

    expect(component.vm.$el.querySelector('emptystate-stub')).not.toBe(null);
  });

  it('should render a loading component', () => {
    store.dispatch('requestFunctionsLoading');
    component = shallowMount(functionsComponent, {
      localVue,
      store,
      propsData: {
        installed: true,
        clustersPath: '',
        helpPath: '',
        statusPath: '',
      },
      sync: false,
    });

    expect(component.vm.$el.querySelector('glloadingicon-stub')).not.toBe(null);
  });

  it('should render empty state when there is no function data', () => {
    store.dispatch('receiveFunctionsNoDataSuccess');
    component = shallowMount(functionsComponent, {
      localVue,
      store,
      propsData: {
        installed: true,
        clustersPath: '',
        helpPath: '',
        statusPath: '',
      },
      sync: false,
    });

    expect(
      component.vm.$el
        .querySelector('.empty-state, .js-empty-state')
        .classList.contains('js-empty-state'),
    ).toBe(true);

    expect(component.vm.$el.querySelector('.state-title, .text-center').innerHTML.trim()).toEqual(
      'No functions available',
    );
  });

  fit('should render the functions list', () => {
    const statusPath = 'statusPath';
    const axiosMock = new AxiosMockAdapter(axios);
    axiosMock.onGet(statusPath).reply(200);

    component = shallowMount(functionsComponent, {
      localVue,
      store,
      propsData: {
        installed: true,
        clustersPath: 'clustersPath',
        helpPath: 'helpPath',
        statusPath,
      },
      sync: false,
    });

    component.vm.$store.dispatch('receiveFunctionsSuccess', mockServerlessFunctions);

    return component.vm.$nextTick().then(() => {
      expect(component.vm.$el.querySelector('environmentrow-stub')).not.toBe(null);
    });
  });
});
