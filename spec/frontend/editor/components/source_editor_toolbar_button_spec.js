import { nextTick } from 'vue';
import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SourceEditorToolbarButton from '~/editor/components/source_editor_toolbar_button.vue';
import { buildButton } from './helpers';

describe('Source Editor Toolbar button', () => {
  let wrapper;
  const defaultBtn = buildButton();

  const findButton = () => wrapper.findComponent(GlButton);

  const createComponent = (props = { button: defaultBtn }) => {
    wrapper = shallowMount(SourceEditorToolbarButton, {
      propsData: {
        ...props,
      },
      stubs: {
        GlButton,
      },
    });
  };

  describe('default', () => {
    const defaultProps = {
      category: 'primary',
      variant: 'default',
    };
    const customProps = {
      category: 'secondary',
      variant: 'info',
    };

    it('does not render the button if the props have not been passed', () => {
      createComponent({});
      expect(findButton().vm).toBeUndefined();
    });

    it('renders a default button without props', async () => {
      createComponent();
      const btn = findButton();
      expect(btn.exists()).toBe(true);
      expect(btn.props()).toMatchObject(defaultProps);
    });

    it('renders a button based on the props passed', async () => {
      createComponent({
        button: customProps,
      });
      const btn = findButton();
      expect(btn.props()).toMatchObject(customProps);
    });

    describe('CSS class', () => {
      let blueprintClasses;

      beforeEach(() => {
        createComponent();
        blueprintClasses = findButton().element.classList;
      });

      it.each`
        cssClass     | expectedExtraClasses
        ${undefined} | ${['']}
        ${''}        | ${['']}
        ${'foo'}     | ${['foo']}
        ${'foo bar'} | ${['foo', 'bar']}
      `(
        'does set CSS class correctly when `class` is "$cssClass"',
        ({ cssClass, expectedExtraClasses }) => {
          createComponent({
            button: {
              ...defaultBtn,
              class: cssClass,
            },
          });
          const btn = findButton().element;
          expectedExtraClasses.forEach((c) => {
            if (c) {
              expect(btn.classList.contains(c)).toBe(true);
            } else {
              expect(btn.classList).toEqual(blueprintClasses);
            }
          });
        },
      );
    });
  });

  describe('data attributes', () => {
    it.each`
      description                                 | data                                        | expectedDataset
      ${'does not set any attribute'}             | ${undefined}                                | ${{}}
      ${'does not set any attribute'}             | ${[]}                                       | ${{}}
      ${'does not set any attribute'}             | ${['foo']}                                  | ${{}}
      ${'does not set any attribute'}             | ${'bar'}                                    | ${{}}
      ${'does set single attribute correctly'}    | ${{ qaSelector: 'foo' }}                    | ${{ qaSelector: 'foo' }}
      ${'does set multiple attributes correctly'} | ${{ qaSelector: 'foo', youCanSeeMe: true }} | ${{ qaSelector: 'foo', youCanSeeMe: 'true' }}
    `('$description when data="$data"', ({ data, expectedDataset }) => {
      createComponent({
        button: {
          data,
        },
      });
      expect(findButton().element.dataset).toEqual(expect.objectContaining(expectedDataset));
    });
  });

  describe('click handler', () => {
    let clickEvent;

    beforeEach(() => {
      clickEvent = new Event('click');
    });

    it('fires the click handler on the button when available', async () => {
      const spy = jest.fn();
      createComponent({
        button: {
          onClick: spy,
        },
      });
      expect(spy).not.toHaveBeenCalled();
      findButton().vm.$emit('click', clickEvent);

      await nextTick();
      expect(spy).toHaveBeenCalledWith(clickEvent);
    });
    it('emits the "click" event, passing the event itself', async () => {
      createComponent();
      jest.spyOn(wrapper.vm, '$emit');
      expect(wrapper.vm.$emit).not.toHaveBeenCalled();

      findButton().vm.$emit('click', clickEvent);
      await nextTick();

      expect(wrapper.vm.$emit).toHaveBeenCalledWith('click', clickEvent);
    });
  });
});
