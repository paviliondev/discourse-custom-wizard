// discourse-skip-module

/**!
* tippy.js v6.3.7
* (c) 2017-2021 atomiks
* MIT License
*/
(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory(require('@popperjs/core')) :
  typeof define === 'function' && define.amd ? define(['@popperjs/core'], factory) :
  (global = global || self, global.tippy = factory(global.Popper));
})(this, (function (core) { 'use strict';

  let ROUND_ARROW = '<svg width="16" height="6" xmlns="http://www.w3.org/2000/svg"><path d="M0 6s1.796-.013 4.67-3.615C5.851.9 6.93.006 8 0c1.07-.006 2.148.887 3.343 2.385C14.233 6.005 16 6 16 6H0z"></svg>';
  let BOX_CLASS = "tippy-box";
  let CONTENT_CLASS = "tippy-content";
  let BACKDROP_CLASS = "tippy-backdrop";
  let ARROW_CLASS = "tippy-arrow";
  let SVG_ARROW_CLASS = "tippy-svg-arrow";
  let TOUCH_OPTIONS = {
    passive: true,
    capture: true
  };
  let TIPPY_DEFAULT_APPEND_TO = function TIPPY_DEFAULT_APPEND_TO() {
    return document.body;
  };

  function hasOwnProperty(obj, key) {
    return {}.hasOwnProperty.call(obj, key);
  }
  function getValueAtIndexOrReturn(value, index, defaultValue) {
    if (Array.isArray(value)) {
      let v = value[index];
      return v == null ? Array.isArray(defaultValue) ? defaultValue[index] : defaultValue : v;
    }

    return value;
  }
  function isType(value, type) {
    let str = {}.toString.call(value);
    return str.indexOf('[object') === 0 && str.indexOf(type + "]") > -1;
  }
  function invokeWithArgsOrReturn(value, args) {
    return typeof value === 'function' ? value.apply(void 0, args) : value;
  }
  function debounce(fn, ms) {
    // Avoid wrapping in `setTimeout` if ms is 0 anyway
    if (ms === 0) {
      return fn;
    }

    let timeout;
    return function (arg) {
      clearTimeout(timeout);
      timeout = setTimeout(function () {
        fn(arg);
      }, ms);
    };
  }
  function removeProperties(obj, keys) {
    let clone = Object.assign({}, obj);
    keys.forEach(function (key) {
      delete clone[key];
    });
    return clone;
  }
  function splitBySpaces(value) {
    return value.split(/\s+/).filter(Boolean);
  }
  function normalizeToArray(value) {
    return [].concat(value);
  }
  function pushIfUnique(arr, value) {
    if (arr.indexOf(value) === -1) {
      arr.push(value);
    }
  }
  function unique(arr) {
    return arr.filter(function (item, index) {
      return arr.indexOf(item) === index;
    });
  }
  function getBasePlacement(placement) {
    return placement.split('-')[0];
  }
  function arrayFrom(value) {
    return [].slice.call(value);
  }
  function removeUndefinedProps(obj) {
    return Object.keys(obj).reduce(function (acc, key) {
      if (obj[key] !== undefined) {
        acc[key] = obj[key];
      }

      return acc;
    }, {});
  }

  function div() {
    return document.createElement('div');
  }
  function isElement(value) {
    return ['Element', 'Fragment'].some(function (type) {
      return isType(value, type);
    });
  }
  function isNodeList(value) {
    return isType(value, 'NodeList');
  }
  function isMouseEvent(value) {
    return isType(value, 'MouseEvent');
  }
  function isReferenceElement(value) {
    return !!(value && value._tippy && value._tippy.reference === value);
  }
  function getArrayOfElements(value) {
    if (isElement(value)) {
      return [value];
    }

    if (isNodeList(value)) {
      return arrayFrom(value);
    }

    if (Array.isArray(value)) {
      return value;
    }

    return arrayFrom(document.querySelectorAll(value));
  }
  function setTransitionDuration(els, value) {
    els.forEach(function (el) {
      if (el) {
        el.style.transitionDuration = value + "ms";
      }
    });
  }
  function setVisibilityState(els, state) {
    els.forEach(function (el) {
      if (el) {
        el.setAttribute('data-state', state);
      }
    });
  }
  function getOwnerDocument(elementOrElements) {
    let _element$ownerDocumen;

    let _normalizeToArray = normalizeToArray(elementOrElements),
        element = _normalizeToArray[0]; // Elements created via a <template> have an ownerDocument with no reference to the body


    return element != null && (_element$ownerDocumen = element.ownerDocument) != null && _element$ownerDocumen.body ? element.ownerDocument : document;
  }
  function isCursorOutsideInteractiveBorder(popperTreeData, event) {
    let clientX = event.clientX,
        clientY = event.clientY;
    return popperTreeData.every(function (_ref) {
      let popperRect = _ref.popperRect,
          popperState = _ref.popperState,
          props = _ref.props;
      let interactiveBorder = props.interactiveBorder;
      let basePlacement = getBasePlacement(popperState.placement);
      let offsetData = popperState.modifiersData.offset;

      if (!offsetData) {
        return true;
      }

      let topDistance = basePlacement === 'bottom' ? offsetData.top.y : 0;
      let bottomDistance = basePlacement === 'top' ? offsetData.bottom.y : 0;
      let leftDistance = basePlacement === 'right' ? offsetData.left.x : 0;
      let rightDistance = basePlacement === 'left' ? offsetData.right.x : 0;
      let exceedsTop = popperRect.top - clientY + topDistance > interactiveBorder;
      let exceedsBottom = clientY - popperRect.bottom - bottomDistance > interactiveBorder;
      let exceedsLeft = popperRect.left - clientX + leftDistance > interactiveBorder;
      let exceedsRight = clientX - popperRect.right - rightDistance > interactiveBorder;
      return exceedsTop || exceedsBottom || exceedsLeft || exceedsRight;
    });
  }
  function updateTransitionEndListener(box, action, listener) {
    let method = action + "EventListener"; // some browsers apparently support `transition` (unprefixed) but only fire
    // `webkitTransitionEnd`...

    ['transitionend', 'webkitTransitionEnd'].forEach(function (event) {
      box[method](event, listener);
    });
  }
  /**
   * Compared to xxx.contains, this function works for dom structures with shadow
   * dom
   */

  function actualContains(parent, child) {
    let target = child;

    while (target) {
      var _target$getRootNode;

      if (parent.contains(target)) {
        return true;
      }

      target = target.getRootNode == null ? void 0 : (_target$getRootNode = target.getRootNode()) == null ? void 0 : _target$getRootNode.host;
    }

    return false;
  }

  let currentInput = {
    isTouch: false
  };
  let lastMouseMoveTime = 0;
  /**
   * When a `touchstart` event is fired, it's assumed the user is using touch
   * input. We'll bind a `mousemove` event listener to listen for mouse input in
   * the future. This way, the `isTouch` property is fully dynamic and will handle
   * hybrid devices that use a mix of touch + mouse input.
   */

  function onDocumentTouchStart() {
    if (currentInput.isTouch) {
      return;
    }

    currentInput.isTouch = true;

    if (window.performance) {
      document.addEventListener('mousemove', onDocumentMouseMove);
    }
  }
  /**
   * When two `mousemove` event are fired consecutively within 20ms, it's assumed
   * the user is using mouse input again. `mousemove` can fire on touch devices as
   * well, but very rarely that quickly.
   */

  function onDocumentMouseMove() {
    let now = performance.now();

    if (now - lastMouseMoveTime < 20) {
      currentInput.isTouch = false;
      document.removeEventListener('mousemove', onDocumentMouseMove);
    }

    lastMouseMoveTime = now;
  }
  /**
   * When an element is in focus and has a tippy, leaving the tab/window and
   * returning causes it to show again. For mouse users this is unexpected, but
   * for keyboard use it makes sense.
   * TODO: find a better technique to solve this problem
   */

  function onWindowBlur() {
    let activeElement = document.activeElement;

    if (isReferenceElement(activeElement)) {
      let instance = activeElement._tippy;

      if (activeElement.blur && !instance.state.isVisible) {
        activeElement.blur();
      }
    }
  }
  function bindGlobalEventListeners() {
    document.addEventListener('touchstart', onDocumentTouchStart, TOUCH_OPTIONS);
    window.addEventListener('blur', onWindowBlur);
  }

  let isBrowser = typeof window !== 'undefined' && typeof document !== 'undefined';
  let isIE11 = isBrowser ? // @ts-ignore
  !!window.msCrypto : false;

  function createMemoryLeakWarning(method) {
    let txt = method === 'destroy' ? 'n already-' : ' ';
    return [method + "() was called on a" + txt + "destroyed instance. This is a no-op but", 'indicates a potential memory leak.'].join(' ');
  }
  function clean(value) {
    let spacesAndTabs = /[ \t]{2,}/g;
    let lineStartWithSpaces = /^[ \t]*/gm;
    return value.replace(spacesAndTabs, ' ').replace(lineStartWithSpaces, '').trim();
  }

  function getDevMessage(message) {
    return clean("\n  %ctippy.js\n\n  %c" + clean(message) + "\n\n  %c\uD83D\uDC77\u200D This is a development-only message. It will be removed in production.\n  ");
  }

  function getFormattedMessage(message) {
    return [getDevMessage(message), // title
    'color: #00C584; font-size: 1.3em; font-weight: bold;', // message
    'line-height: 1.5', // footer
    'color: #a6a095;'];
  } // Assume warnings and errors never have the same message

  let visitedMessages;

  {
    resetVisitedMessages();
  }

  function resetVisitedMessages() {
    visitedMessages = new Set();
  }
  function warnWhen(condition, message) {
    if (condition && !visitedMessages.has(message)) {
      let _console;

      visitedMessages.add(message);

      (_console = console).warn.apply(_console, getFormattedMessage(message));
    }
  }
  function errorWhen(condition, message) {
    if (condition && !visitedMessages.has(message)) {
      let _console2;

      visitedMessages.add(message);

      (_console2 = console).error.apply(_console2, getFormattedMessage(message));
    }
  }
  function validateTargets(targets) {
    let didPassFalsyValue = !targets;
    let didPassPlainObject = Object.prototype.toString.call(targets) === '[object Object]' && !targets.addEventListener;
    errorWhen(didPassFalsyValue, ['tippy() was passed', '`' + String(targets) + '`', 'as its targets (first) argument. Valid types are: String, Element,', 'Element[], or NodeList.'].join(' '));
    errorWhen(didPassPlainObject, ['tippy() was passed a plain object which is not supported as an argument', 'for virtual positioning. Use props.getReferenceClientRect instead.'].join(' '));
  }

  let pluginProps = {
    animateFill: false,
    followCursor: false,
    inlinePositioning: false,
    sticky: false
  };
  let renderProps = {
    allowHTML: false,
    animation: 'fade',
    arrow: true,
    content: '',
    inertia: false,
    maxWidth: 350,
    role: 'tooltip',
    theme: '',
    zIndex: 9999
  };
  let defaultProps = Object.assign({
    appendTo: TIPPY_DEFAULT_APPEND_TO,
    aria: {
      content: 'auto',
      expanded: 'auto'
    },
    delay: 0,
    duration: [300, 250],
    getReferenceClientRect: null,
    hideOnClick: true,
    ignoreAttributes: false,
    interactive: false,
    interactiveBorder: 2,
    interactiveDebounce: 0,
    moveTransition: '',
    offset: [0, 10],
    onAfterUpdate: function onAfterUpdate() {},
    onBeforeUpdate: function onBeforeUpdate() {},
    onCreate: function onCreate() {},
    onDestroy: function onDestroy() {},
    onHidden: function onHidden() {},
    onHide: function onHide() {},
    onMount: function onMount() {},
    onShow: function onShow() {},
    onShown: function onShown() {},
    onTrigger: function onTrigger() {},
    onUntrigger: function onUntrigger() {},
    onClickOutside: function onClickOutside() {},
    placement: 'top',
    plugins: [],
    popperOptions: {},
    render: null,
    showOnCreate: false,
    touch: true,
    trigger: 'mouseenter focus',
    triggerTarget: null
  }, pluginProps, renderProps);
  let defaultKeys = Object.keys(defaultProps);
  let setDefaultProps = function setDefaultProps(partialProps) {
    /* istanbul ignore else */
    {
      validateProps(partialProps, []);
    }

    let keys = Object.keys(partialProps);
    keys.forEach(function (key) {
      defaultProps[key] = partialProps[key];
    });
  };
  function getExtendedPassedProps(passedProps) {
    let plugins = passedProps.plugins || [];
    let pluginProps = plugins.reduce(function (acc, plugin) {
      let name = plugin.name,
          defaultValue = plugin.defaultValue;

      if (name) {
        let _name;

        acc[name] = passedProps[name] !== undefined ? passedProps[name] : (_name = defaultProps[name]) != null ? _name : defaultValue;
      }

      return acc;
    }, {});
    return Object.assign({}, passedProps, pluginProps);
  }
  function getDataAttributeProps(reference, plugins) {
    let propKeys = plugins ? Object.keys(getExtendedPassedProps(Object.assign({}, defaultProps, {
      plugins
    }))) : defaultKeys;
    let props = propKeys.reduce(function (acc, key) {
      let valueAsString = (reference.getAttribute("data-tippy-" + key) || '').trim();

      if (!valueAsString) {
        return acc;
      }

      if (key === 'content') {
        acc[key] = valueAsString;
      } else {
        try {
          acc[key] = JSON.parse(valueAsString);
        } catch (e) {
          acc[key] = valueAsString;
        }
      }

      return acc;
    }, {});
    return props;
  }
  function evaluateProps(reference, props) {
    let out = Object.assign({}, props, {
      content: invokeWithArgsOrReturn(props.content, [reference])
    }, props.ignoreAttributes ? {} : getDataAttributeProps(reference, props.plugins));
    out.aria = Object.assign({}, defaultProps.aria, out.aria);
    out.aria = {
      expanded: out.aria.expanded === 'auto' ? props.interactive : out.aria.expanded,
      content: out.aria.content === 'auto' ? props.interactive ? null : 'describedby' : out.aria.content
    };
    return out;
  }
  function validateProps(partialProps, plugins) {
    if (partialProps === void 0) {
      partialProps = {};
    }

    if (plugins === void 0) {
      plugins = [];
    }

    let keys = Object.keys(partialProps);
    keys.forEach(function (prop) {
      let nonPluginProps = removeProperties(defaultProps, Object.keys(pluginProps));
      let didPassUnknownProp = !hasOwnProperty(nonPluginProps, prop); // Check if the prop exists in `plugins`

      if (didPassUnknownProp) {
        didPassUnknownProp = plugins.filter(function (plugin) {
          return plugin.name === prop;
        }).length === 0;
      }

      warnWhen(didPassUnknownProp, ["`" + prop + "`", "is not a valid prop. You may have spelled it incorrectly, or if it's", 'a plugin, forgot to pass it in an array as props.plugins.', '\n\n', 'All props: https://atomiks.github.io/tippyjs/v6/all-props/\n', 'Plugins: https://atomiks.github.io/tippyjs/v6/plugins/'].join(' '));
    });
  }

  let innerHTML = function innerHTML() {
    return 'innerHTML';
  };

  function dangerouslySetInnerHTML(element, html) {
    element[innerHTML()] = html;
  }

  function createArrowElement(value) {
    let arrow = div();

    if (value === true) {
      arrow.className = ARROW_CLASS;
    } else {
      arrow.className = SVG_ARROW_CLASS;

      if (isElement(value)) {
        arrow.appendChild(value);
      } else {
        dangerouslySetInnerHTML(arrow, value);
      }
    }

    return arrow;
  }

  function setContent(content, props) {
    if (isElement(props.content)) {
      dangerouslySetInnerHTML(content, '');
      content.appendChild(props.content);
    } else if (typeof props.content !== 'function') {
      if (props.allowHTML) {
        dangerouslySetInnerHTML(content, props.content);
      } else {
        content.textContent = props.content;
      }
    }
  }
  function getChildren(popper) {
    let box = popper.firstElementChild;
    let boxChildren = arrayFrom(box.children);
    return {
      box,
      content: boxChildren.find(function (node) {
        return node.classList.contains(CONTENT_CLASS);
      }),
      arrow: boxChildren.find(function (node) {
        return node.classList.contains(ARROW_CLASS) || node.classList.contains(SVG_ARROW_CLASS);
      }),
      backdrop: boxChildren.find(function (node) {
        return node.classList.contains(BACKDROP_CLASS);
      })
    };
  }
  function render(instance) {
    let popper = div();
    let box = div();
    box.className = BOX_CLASS;
    box.setAttribute('data-state', 'hidden');
    box.setAttribute('tabindex', '-1');
    let content = div();
    content.className = CONTENT_CLASS;
    content.setAttribute('data-state', 'hidden');
    setContent(content, instance.props);
    popper.appendChild(box);
    box.appendChild(content);
    onUpdate(instance.props, instance.props);

    function onUpdate(prevProps, nextProps) {
      let _getChildren = getChildren(popper),
          box = _getChildren.box,
          content = _getChildren.content,
          arrow = _getChildren.arrow;

      if (nextProps.theme) {
        box.setAttribute('data-theme', nextProps.theme);
      } else {
        box.removeAttribute('data-theme');
      }

      if (typeof nextProps.animation === 'string') {
        box.setAttribute('data-animation', nextProps.animation);
      } else {
        box.removeAttribute('data-animation');
      }

      if (nextProps.inertia) {
        box.setAttribute('data-inertia', '');
      } else {
        box.removeAttribute('data-inertia');
      }

      box.style.maxWidth = typeof nextProps.maxWidth === 'number' ? nextProps.maxWidth + "px" : nextProps.maxWidth;

      if (nextProps.role) {
        box.setAttribute('role', nextProps.role);
      } else {
        box.removeAttribute('role');
      }

      if (prevProps.content !== nextProps.content || prevProps.allowHTML !== nextProps.allowHTML) {
        setContent(content, instance.props);
      }

      if (nextProps.arrow) {
        if (!arrow) {
          box.appendChild(createArrowElement(nextProps.arrow));
        } else if (prevProps.arrow !== nextProps.arrow) {
          box.removeChild(arrow);
          box.appendChild(createArrowElement(nextProps.arrow));
        }
      } else if (arrow) {
        box.removeChild(arrow);
      }
    }

    return {
      popper,
      onUpdate
    };
  } // Runtime check to identify if the render function is the default one; this
  // way we can apply default CSS transitions logic and it can be tree-shaken away

  render.$$tippy = true;

  let idCounter = 1;
  let mouseMoveListeners = []; // Used by `hideAll()`

  let mountedInstances = [];
  function createTippy(reference, passedProps) {
    let props = evaluateProps(reference, Object.assign({}, defaultProps, getExtendedPassedProps(removeUndefinedProps(passedProps)))); // ===========================================================================
    // 🔒 Private members
    // ===========================================================================

    let showTimeout;
    let hideTimeout;
    let scheduleHideAnimationFrame;
    let isVisibleFromClick = false;
    let didHideDueToDocumentMouseDown = false;
    let didTouchMove = false;
    let ignoreOnFirstUpdate = false;
    let lastTriggerEvent;
    let currentTransitionEndListener;
    let onFirstUpdate;
    let listeners = [];
    let debouncedOnMouseMove = debounce(onMouseMove, props.interactiveDebounce);
    let currentTarget; // ===========================================================================
    // 🔑 Public members
    // ===========================================================================

    let id = idCounter++;
    let popperInstance = null;
    let plugins = unique(props.plugins);
    let state = {
      // Is the instance currently enabled?
      isEnabled: true,
      // Is the tippy currently showing and not transitioning out?
      isVisible: false,
      // Has the instance been destroyed?
      isDestroyed: false,
      // Is the tippy currently mounted to the DOM?
      isMounted: false,
      // Has the tippy finished transitioning in?
      isShown: false
    };
    let instance = {
      // properties
      id,
      reference,
      popper: div(),
      popperInstance,
      props,
      state,
      plugins,
      // methods
      clearDelayTimeouts,
      setProps,
      setContent,
      show,
      hide,
      hideWithInteractivity,
      enable,
      disable,
      unmount,
      destroy
    }; // TODO: Investigate why this early return causes a TDZ error in the tests —
    // it doesn't seem to happen in the browser

    /* istanbul ignore if */

    if (!props.render) {
      {
        errorWhen(true, 'render() function has not been supplied.');
      }

      return instance;
    } // ===========================================================================
    // Initial mutations
    // ===========================================================================


    let _props$render = props.render(instance),
        popper = _props$render.popper,
        onUpdate = _props$render.onUpdate;

    popper.setAttribute('data-tippy-root', '');
    popper.id = "tippy-" + instance.id;
    instance.popper = popper;
    reference._tippy = instance;
    popper._tippy = instance;
    let pluginsHooks = plugins.map(function (plugin) {
      return plugin.fn(instance);
    });
    let hasAriaExpanded = reference.hasAttribute('aria-expanded');
    addListeners();
    handleAriaExpandedAttribute();
    handleStyles();
    invokeHook('onCreate', [instance]);

    if (props.showOnCreate) {
      scheduleShow();
    } // Prevent a tippy with a delay from hiding if the cursor left then returned
    // before it started hiding


    popper.addEventListener('mouseenter', function () {
      if (instance.props.interactive && instance.state.isVisible) {
        instance.clearDelayTimeouts();
      }
    });
    popper.addEventListener('mouseleave', function () {
      if (instance.props.interactive && instance.props.trigger.indexOf('mouseenter') >= 0) {
        getDocument().addEventListener('mousemove', debouncedOnMouseMove);
      }
    });
    return instance; // ===========================================================================
    // 🔒 Private methods
    // ===========================================================================

    function getNormalizedTouchSettings() {
      let touch = instance.props.touch;
      return Array.isArray(touch) ? touch : [touch, 0];
    }

    function getIsCustomTouchBehavior() {
      return getNormalizedTouchSettings()[0] === 'hold';
    }

    function getIsDefaultRenderFn() {
      let _instance$props$rende;

      // @ts-ignore
      return !!((_instance$props$rende = instance.props.render) != null && _instance$props$rende.$$tippy);
    }

    function getCurrentTarget() {
      return currentTarget || reference;
    }

    function getDocument() {
      let parent = getCurrentTarget().parentNode;
      return parent ? getOwnerDocument(parent) : document;
    }

    function getDefaultTemplateChildren() {
      return getChildren(popper);
    }

    function getDelay(isShow) {
      // For touch or keyboard input, force `0` delay for UX reasons
      // Also if the instance is mounted but not visible (transitioning out),
      // ignore delay
      if (instance.state.isMounted && !instance.state.isVisible || currentInput.isTouch || lastTriggerEvent && lastTriggerEvent.type === 'focus') {
        return 0;
      }

      return getValueAtIndexOrReturn(instance.props.delay, isShow ? 0 : 1, defaultProps.delay);
    }

    function handleStyles(fromHide) {
      if (fromHide === void 0) {
        fromHide = false;
      }

      popper.style.pointerEvents = instance.props.interactive && !fromHide ? '' : 'none';
      popper.style.zIndex = "" + instance.props.zIndex;
    }

    function invokeHook(hook, args, shouldInvokePropsHook) {
      if (shouldInvokePropsHook === void 0) {
        shouldInvokePropsHook = true;
      }

      pluginsHooks.forEach(function (pluginHooks) {
        if (pluginHooks[hook]) {
          pluginHooks[hook].apply(pluginHooks, args);
        }
      });

      if (shouldInvokePropsHook) {
        let _instance$props;

        (_instance$props = instance.props)[hook].apply(_instance$props, args);
      }
    }

    function handleAriaContentAttribute() {
      let aria = instance.props.aria;

      if (!aria.content) {
        return;
      }

      let attr = "aria-" + aria.content;
      let id = popper.id;
      let nodes = normalizeToArray(instance.props.triggerTarget || reference);
      nodes.forEach(function (node) {
        let currentValue = node.getAttribute(attr);

        if (instance.state.isVisible) {
          node.setAttribute(attr, currentValue ? currentValue + " " + id : id);
        } else {
          let nextValue = currentValue && currentValue.replace(id, '').trim();

          if (nextValue) {
            node.setAttribute(attr, nextValue);
          } else {
            node.removeAttribute(attr);
          }
        }
      });
    }

    function handleAriaExpandedAttribute() {
      if (hasAriaExpanded || !instance.props.aria.expanded) {
        return;
      }

      let nodes = normalizeToArray(instance.props.triggerTarget || reference);
      nodes.forEach(function (node) {
        if (instance.props.interactive) {
          node.setAttribute('aria-expanded', instance.state.isVisible && node === getCurrentTarget() ? 'true' : 'false');
        } else {
          node.removeAttribute('aria-expanded');
        }
      });
    }

    function cleanupInteractiveMouseListeners() {
      getDocument().removeEventListener('mousemove', debouncedOnMouseMove);
      mouseMoveListeners = mouseMoveListeners.filter(function (listener) {
        return listener !== debouncedOnMouseMove;
      });
    }

    function onDocumentPress(event) {
      // Moved finger to scroll instead of an intentional tap outside
      if (currentInput.isTouch) {
        if (didTouchMove || event.type === 'mousedown') {
          return;
        }
      }

      let actualTarget = event.composedPath && event.composedPath()[0] || event.target; // Clicked on interactive popper

      if (instance.props.interactive && actualContains(popper, actualTarget)) {
        return;
      } // Clicked on the event listeners target


      if (normalizeToArray(instance.props.triggerTarget || reference).some(function (el) {
        return actualContains(el, actualTarget);
      })) {
        if (currentInput.isTouch) {
          return;
        }

        if (instance.state.isVisible && instance.props.trigger.indexOf('click') >= 0) {
          return;
        }
      } else {
        invokeHook('onClickOutside', [instance, event]);
      }

      if (instance.props.hideOnClick === true) {
        instance.clearDelayTimeouts();
        instance.hide(); // `mousedown` event is fired right before `focus` if pressing the
        // currentTarget. This lets a tippy with `focus` trigger know that it
        // should not show

        didHideDueToDocumentMouseDown = true;
        setTimeout(function () {
          didHideDueToDocumentMouseDown = false;
        }); // The listener gets added in `scheduleShow()`, but this may be hiding it
        // before it shows, and hide()'s early bail-out behavior can prevent it
        // from being cleaned up

        if (!instance.state.isMounted) {
          removeDocumentPress();
        }
      }
    }

    function onTouchMove() {
      didTouchMove = true;
    }

    function onTouchStart() {
      didTouchMove = false;
    }

    function addDocumentPress() {
      let doc = getDocument();
      doc.addEventListener('mousedown', onDocumentPress, true);
      doc.addEventListener('touchend', onDocumentPress, TOUCH_OPTIONS);
      doc.addEventListener('touchstart', onTouchStart, TOUCH_OPTIONS);
      doc.addEventListener('touchmove', onTouchMove, TOUCH_OPTIONS);
    }

    function removeDocumentPress() {
      let doc = getDocument();
      doc.removeEventListener('mousedown', onDocumentPress, true);
      doc.removeEventListener('touchend', onDocumentPress, TOUCH_OPTIONS);
      doc.removeEventListener('touchstart', onTouchStart, TOUCH_OPTIONS);
      doc.removeEventListener('touchmove', onTouchMove, TOUCH_OPTIONS);
    }

    function onTransitionedOut(duration, callback) {
      onTransitionEnd(duration, function () {
        if (!instance.state.isVisible && popper.parentNode && popper.parentNode.contains(popper)) {
          callback();
        }
      });
    }

    function onTransitionedIn(duration, callback) {
      onTransitionEnd(duration, callback);
    }

    function onTransitionEnd(duration, callback) {
      let box = getDefaultTemplateChildren().box;

      function listener(event) {
        if (event.target === box) {
          updateTransitionEndListener(box, 'remove', listener);
          callback();
        }
      } // Make callback synchronous if duration is 0
      // `transitionend` won't fire otherwise


      if (duration === 0) {
        return callback();
      }

      updateTransitionEndListener(box, 'remove', currentTransitionEndListener);
      updateTransitionEndListener(box, 'add', listener);
      currentTransitionEndListener = listener;
    }

    function on(eventType, handler, options) {
      if (options === void 0) {
        options = false;
      }

      let nodes = normalizeToArray(instance.props.triggerTarget || reference);
      nodes.forEach(function (node) {
        node.addEventListener(eventType, handler, options);
        listeners.push({
          node,
          eventType,
          handler,
          options
        });
      });
    }

    function addListeners() {
      if (getIsCustomTouchBehavior()) {
        on('touchstart', onTrigger, {
          passive: true
        });
        on('touchend', onMouseLeave, {
          passive: true
        });
      }

      splitBySpaces(instance.props.trigger).forEach(function (eventType) {
        if (eventType === 'manual') {
          return;
        }

        on(eventType, onTrigger);

        switch (eventType) {
          case 'mouseenter':
            on('mouseleave', onMouseLeave);
            break;

          case 'focus':
            on(isIE11 ? 'focusout' : 'blur', onBlurOrFocusOut);
            break;

          case 'focusin':
            on('focusout', onBlurOrFocusOut);
            break;
        }
      });
    }

    function removeListeners() {
      listeners.forEach(function (_ref) {
        let node = _ref.node,
            eventType = _ref.eventType,
            handler = _ref.handler,
            options = _ref.options;
        node.removeEventListener(eventType, handler, options);
      });
      listeners = [];
    }

    function onTrigger(event) {
      let _lastTriggerEvent;

      let shouldScheduleClickHide = false;

      if (!instance.state.isEnabled || isEventListenerStopped(event) || didHideDueToDocumentMouseDown) {
        return;
      }

      let wasFocused = ((_lastTriggerEvent = lastTriggerEvent) == null ? void 0 : _lastTriggerEvent.type) === 'focus';
      lastTriggerEvent = event;
      currentTarget = event.currentTarget;
      handleAriaExpandedAttribute();

      if (!instance.state.isVisible && isMouseEvent(event)) {
        // If scrolling, `mouseenter` events can be fired if the cursor lands
        // over a new target, but `mousemove` events don't get fired. This
        // causes interactive tooltips to get stuck open until the cursor is
        // moved
        mouseMoveListeners.forEach(function (listener) {
          return listener(event);
        });
      } // Toggle show/hide when clicking click-triggered tooltips


      if (event.type === 'click' && (instance.props.trigger.indexOf('mouseenter') < 0 || isVisibleFromClick) && instance.props.hideOnClick !== false && instance.state.isVisible) {
        shouldScheduleClickHide = true;
      } else {
        scheduleShow(event);
      }

      if (event.type === 'click') {
        isVisibleFromClick = !shouldScheduleClickHide;
      }

      if (shouldScheduleClickHide && !wasFocused) {
        scheduleHide(event);
      }
    }

    function onMouseMove(event) {
      let target = event.target;
      let isCursorOverReferenceOrPopper = getCurrentTarget().contains(target) || popper.contains(target);

      if (event.type === 'mousemove' && isCursorOverReferenceOrPopper) {
        return;
      }

      let popperTreeData = getNestedPopperTree().concat(popper).map(function (popper) {
        let _instance$popperInsta;

        let instance = popper._tippy;
        let state = (_instance$popperInsta = instance.popperInstance) == null ? void 0 : _instance$popperInsta.state;

        if (state) {
          return {
            popperRect: popper.getBoundingClientRect(),
            popperState: state,
            props
          };
        }

        return null;
      }).filter(Boolean);

      if (isCursorOutsideInteractiveBorder(popperTreeData, event)) {
        cleanupInteractiveMouseListeners();
        scheduleHide(event);
      }
    }

    function onMouseLeave(event) {
      let shouldBail = isEventListenerStopped(event) || instance.props.trigger.indexOf('click') >= 0 && isVisibleFromClick;

      if (shouldBail) {
        return;
      }

      if (instance.props.interactive) {
        instance.hideWithInteractivity(event);
        return;
      }

      scheduleHide(event);
    }

    function onBlurOrFocusOut(event) {
      if (instance.props.trigger.indexOf('focusin') < 0 && event.target !== getCurrentTarget()) {
        return;
      } // If focus was moved to within the popper


      if (instance.props.interactive && event.relatedTarget && popper.contains(event.relatedTarget)) {
        return;
      }

      scheduleHide(event);
    }

    function isEventListenerStopped(event) {
      return currentInput.isTouch ? getIsCustomTouchBehavior() !== event.type.indexOf('touch') >= 0 : false;
    }

    function createPopperInstance() {
      destroyPopperInstance();
      let _instance$props2 = instance.props,
          popperOptions = _instance$props2.popperOptions,
          placement = _instance$props2.placement,
          offset = _instance$props2.offset,
          getReferenceClientRect = _instance$props2.getReferenceClientRect,
          moveTransition = _instance$props2.moveTransition;
      let arrow = getIsDefaultRenderFn() ? getChildren(popper).arrow : null;
      let computedReference = getReferenceClientRect ? {
        getBoundingClientRect: getReferenceClientRect,
        contextElement: getReferenceClientRect.contextElement || getCurrentTarget()
      } : reference;
      let tippyModifier = {
        name: '$$tippy',
        enabled: true,
        phase: 'beforeWrite',
        requires: ['computeStyles'],
        fn: function fn(_ref2) {
          let state = _ref2.state;

          if (getIsDefaultRenderFn()) {
            let _getDefaultTemplateCh = getDefaultTemplateChildren(),
                box = _getDefaultTemplateCh.box;

            ['placement', 'reference-hidden', 'escaped'].forEach(function (attr) {
              if (attr === 'placement') {
                box.setAttribute('data-placement', state.placement);
              } else {
                if (state.attributes.popper["data-popper-" + attr]) {
                  box.setAttribute("data-" + attr, '');
                } else {
                  box.removeAttribute("data-" + attr);
                }
              }
            });
            state.attributes.popper = {};
          }
        }
      };
      let modifiers = [{
        name: 'offset',
        options: {
          offset
        }
      }, {
        name: 'preventOverflow',
        options: {
          padding: {
            top: 2,
            bottom: 2,
            left: 5,
            right: 5
          }
        }
      }, {
        name: 'flip',
        options: {
          padding: 5
        }
      }, {
        name: 'computeStyles',
        options: {
          adaptive: !moveTransition
        }
      }, tippyModifier];

      if (getIsDefaultRenderFn() && arrow) {
        modifiers.push({
          name: 'arrow',
          options: {
            element: arrow,
            padding: 3
          }
        });
      }

      modifiers.push.apply(modifiers, (popperOptions == null ? void 0 : popperOptions.modifiers) || []);
      instance.popperInstance = core.createPopper(computedReference, popper, Object.assign({}, popperOptions, {
        placement,
        onFirstUpdate,
        modifiers
      }));
    }

    function destroyPopperInstance() {
      if (instance.popperInstance) {
        instance.popperInstance.destroy();
        instance.popperInstance = null;
      }
    }

    function mount() {
      let appendTo = instance.props.appendTo;
      let parentNode; // By default, we'll append the popper to the triggerTargets's parentNode so
      // it's directly after the reference element so the elements inside the
      // tippy can be tabbed to
      // If there are clipping issues, the user can specify a different appendTo
      // and ensure focus management is handled correctly manually

      let node = getCurrentTarget();

      if (instance.props.interactive && appendTo === TIPPY_DEFAULT_APPEND_TO || appendTo === 'parent') {
        parentNode = node.parentNode;
      } else {
        parentNode = invokeWithArgsOrReturn(appendTo, [node]);
      } // The popper element needs to exist on the DOM before its position can be
      // updated as Popper needs to read its dimensions


      if (!parentNode.contains(popper)) {
        parentNode.appendChild(popper);
      }

      instance.state.isMounted = true;
      createPopperInstance();
      /* istanbul ignore else */

      {
        // Accessibility check
        warnWhen(instance.props.interactive && appendTo === defaultProps.appendTo && node.nextElementSibling !== popper, ['Interactive tippy element may not be accessible via keyboard', 'navigation because it is not directly after the reference element', 'in the DOM source order.', '\n\n', 'Using a wrapper <div> or <span> tag around the reference element', 'solves this by creating a new parentNode context.', '\n\n', 'Specifying `appendTo: document.body` silences this warning, but it', 'assumes you are using a focus management solution to handle', 'keyboard navigation.', '\n\n', 'See: https://atomiks.github.io/tippyjs/v6/accessibility/#interactivity'].join(' '));
      }
    }

    function getNestedPopperTree() {
      return arrayFrom(popper.querySelectorAll('[data-tippy-root]'));
    }

    function scheduleShow(event) {
      instance.clearDelayTimeouts();

      if (event) {
        invokeHook('onTrigger', [instance, event]);
      }

      addDocumentPress();
      let delay = getDelay(true);

      let _getNormalizedTouchSe = getNormalizedTouchSettings(),
          touchValue = _getNormalizedTouchSe[0],
          touchDelay = _getNormalizedTouchSe[1];

      if (currentInput.isTouch && touchValue === 'hold' && touchDelay) {
        delay = touchDelay;
      }

      if (delay) {
        showTimeout = setTimeout(function () {
          instance.show();
        }, delay);
      } else {
        instance.show();
      }
    }

    function scheduleHide(event) {
      instance.clearDelayTimeouts();
      invokeHook('onUntrigger', [instance, event]);

      if (!instance.state.isVisible) {
        removeDocumentPress();
        return;
      } // For interactive tippies, scheduleHide is added to a document.body handler
      // from onMouseLeave so must intercept scheduled hides from mousemove/leave
      // events when trigger contains mouseenter and click, and the tip is
      // currently shown as a result of a click.


      if (instance.props.trigger.indexOf('mouseenter') >= 0 && instance.props.trigger.indexOf('click') >= 0 && ['mouseleave', 'mousemove'].indexOf(event.type) >= 0 && isVisibleFromClick) {
        return;
      }

      let delay = getDelay(false);

      if (delay) {
        hideTimeout = setTimeout(function () {
          if (instance.state.isVisible) {
            instance.hide();
          }
        }, delay);
      } else {
        // Fixes a `transitionend` problem when it fires 1 frame too
        // late sometimes, we don't want hide() to be called.
        scheduleHideAnimationFrame = requestAnimationFrame(function () {
          instance.hide();
        });
      }
    } // ===========================================================================
    // 🔑 Public methods
    // ===========================================================================


    function enable() {
      instance.state.isEnabled = true;
    }

    function disable() {
      // Disabling the instance should also hide it
      // https://github.com/atomiks/tippy.js-react/issues/106
      instance.hide();
      instance.state.isEnabled = false;
    }

    function clearDelayTimeouts() {
      clearTimeout(showTimeout);
      clearTimeout(hideTimeout);
      cancelAnimationFrame(scheduleHideAnimationFrame);
    }

    function setProps(partialProps) {
      /* istanbul ignore else */
      {
        warnWhen(instance.state.isDestroyed, createMemoryLeakWarning('setProps'));
      }

      if (instance.state.isDestroyed) {
        return;
      }

      invokeHook('onBeforeUpdate', [instance, partialProps]);
      removeListeners();
      let prevProps = instance.props;
      let nextProps = evaluateProps(reference, Object.assign({}, prevProps, removeUndefinedProps(partialProps), {
        ignoreAttributes: true
      }));
      instance.props = nextProps;
      addListeners();

      if (prevProps.interactiveDebounce !== nextProps.interactiveDebounce) {
        cleanupInteractiveMouseListeners();
        debouncedOnMouseMove = debounce(onMouseMove, nextProps.interactiveDebounce);
      } // Ensure stale aria-expanded attributes are removed


      if (prevProps.triggerTarget && !nextProps.triggerTarget) {
        normalizeToArray(prevProps.triggerTarget).forEach(function (node) {
          node.removeAttribute('aria-expanded');
        });
      } else if (nextProps.triggerTarget) {
        reference.removeAttribute('aria-expanded');
      }

      handleAriaExpandedAttribute();
      handleStyles();

      if (onUpdate) {
        onUpdate(prevProps, nextProps);
      }

      if (instance.popperInstance) {
        createPopperInstance(); // Fixes an issue with nested tippies if they are all getting re-rendered,
        // and the nested ones get re-rendered first.
        // https://github.com/atomiks/tippyjs-react/issues/177
        // TODO: find a cleaner / more efficient solution(!)

        getNestedPopperTree().forEach(function (nestedPopper) {
          // React (and other UI libs likely) requires a rAF wrapper as it flushes
          // its work in one
          requestAnimationFrame(nestedPopper._tippy.popperInstance.forceUpdate);
        });
      }

      invokeHook('onAfterUpdate', [instance, partialProps]);
    }

    function setContent(content) {
      instance.setProps({
        content
      });
    }

    function show() {
      /* istanbul ignore else */
      {
        warnWhen(instance.state.isDestroyed, createMemoryLeakWarning('show'));
      } // Early bail-out


      let isAlreadyVisible = instance.state.isVisible;
      let isDestroyed = instance.state.isDestroyed;
      let isDisabled = !instance.state.isEnabled;
      let isTouchAndTouchDisabled = currentInput.isTouch && !instance.props.touch;
      let duration = getValueAtIndexOrReturn(instance.props.duration, 0, defaultProps.duration);

      if (isAlreadyVisible || isDestroyed || isDisabled || isTouchAndTouchDisabled) {
        return;
      } // Normalize `disabled` behavior across browsers.
      // Firefox allows events on disabled elements, but Chrome doesn't.
      // Using a wrapper element (i.e. <span>) is recommended.


      if (getCurrentTarget().hasAttribute('disabled')) {
        return;
      }

      invokeHook('onShow', [instance], false);

      if (instance.props.onShow(instance) === false) {
        return;
      }

      instance.state.isVisible = true;

      if (getIsDefaultRenderFn()) {
        popper.style.visibility = 'visible';
      }

      handleStyles();
      addDocumentPress();

      if (!instance.state.isMounted) {
        popper.style.transition = 'none';
      } // If flipping to the opposite side after hiding at least once, the
      // animation will use the wrong placement without resetting the duration


      if (getIsDefaultRenderFn()) {
        let _getDefaultTemplateCh2 = getDefaultTemplateChildren(),
            box = _getDefaultTemplateCh2.box,
            content = _getDefaultTemplateCh2.content;

        setTransitionDuration([box, content], 0);
      }

      onFirstUpdate = function onFirstUpdate() {
        let _instance$popperInsta2;

        if (!instance.state.isVisible || ignoreOnFirstUpdate) {
          return;
        }

        ignoreOnFirstUpdate = true; // reflow

        void popper.offsetHeight;
        popper.style.transition = instance.props.moveTransition;

        if (getIsDefaultRenderFn() && instance.props.animation) {
          let _getDefaultTemplateCh3 = getDefaultTemplateChildren(),
              _box = _getDefaultTemplateCh3.box,
              _content = _getDefaultTemplateCh3.content;

          setTransitionDuration([_box, _content], duration);
          setVisibilityState([_box, _content], 'visible');
        }

        handleAriaContentAttribute();
        handleAriaExpandedAttribute();
        pushIfUnique(mountedInstances, instance); // certain modifiers (e.g. `maxSize`) require a second update after the
        // popper has been positioned for the first time

        (_instance$popperInsta2 = instance.popperInstance) == null ? void 0 : _instance$popperInsta2.forceUpdate();
        invokeHook('onMount', [instance]);

        if (instance.props.animation && getIsDefaultRenderFn()) {
          onTransitionedIn(duration, function () {
            instance.state.isShown = true;
            invokeHook('onShown', [instance]);
          });
        }
      };

      mount();
    }

    function hide() {
      /* istanbul ignore else */
      {
        warnWhen(instance.state.isDestroyed, createMemoryLeakWarning('hide'));
      } // Early bail-out


      let isAlreadyHidden = !instance.state.isVisible;
      let isDestroyed = instance.state.isDestroyed;
      let isDisabled = !instance.state.isEnabled;
      let duration = getValueAtIndexOrReturn(instance.props.duration, 1, defaultProps.duration);

      if (isAlreadyHidden || isDestroyed || isDisabled) {
        return;
      }

      invokeHook('onHide', [instance], false);

      if (instance.props.onHide(instance) === false) {
        return;
      }

      instance.state.isVisible = false;
      instance.state.isShown = false;
      ignoreOnFirstUpdate = false;
      isVisibleFromClick = false;

      if (getIsDefaultRenderFn()) {
        popper.style.visibility = 'hidden';
      }

      cleanupInteractiveMouseListeners();
      removeDocumentPress();
      handleStyles(true);

      if (getIsDefaultRenderFn()) {
        let _getDefaultTemplateCh4 = getDefaultTemplateChildren(),
            box = _getDefaultTemplateCh4.box,
            content = _getDefaultTemplateCh4.content;

        if (instance.props.animation) {
          setTransitionDuration([box, content], duration);
          setVisibilityState([box, content], 'hidden');
        }
      }

      handleAriaContentAttribute();
      handleAriaExpandedAttribute();

      if (instance.props.animation) {
        if (getIsDefaultRenderFn()) {
          onTransitionedOut(duration, instance.unmount);
        }
      } else {
        instance.unmount();
      }
    }

    function hideWithInteractivity(event) {
      /* istanbul ignore else */
      {
        warnWhen(instance.state.isDestroyed, createMemoryLeakWarning('hideWithInteractivity'));
      }

      getDocument().addEventListener('mousemove', debouncedOnMouseMove);
      pushIfUnique(mouseMoveListeners, debouncedOnMouseMove);
      debouncedOnMouseMove(event);
    }

    function unmount() {
      /* istanbul ignore else */
      {
        warnWhen(instance.state.isDestroyed, createMemoryLeakWarning('unmount'));
      }

      if (instance.state.isVisible) {
        instance.hide();
      }

      if (!instance.state.isMounted) {
        return;
      }

      destroyPopperInstance(); // If a popper is not interactive, it will be appended outside the popper
      // tree by default. This seems mainly for interactive tippies, but we should
      // find a workaround if possible

      getNestedPopperTree().forEach(function (nestedPopper) {
        nestedPopper._tippy.unmount();
      });

      if (popper.parentNode) {
        popper.parentNode.removeChild(popper);
      }

      mountedInstances = mountedInstances.filter(function (i) {
        return i !== instance;
      });
      instance.state.isMounted = false;
      invokeHook('onHidden', [instance]);
    }

    function destroy() {
      /* istanbul ignore else */
      {
        warnWhen(instance.state.isDestroyed, createMemoryLeakWarning('destroy'));
      }

      if (instance.state.isDestroyed) {
        return;
      }

      instance.clearDelayTimeouts();
      instance.unmount();
      removeListeners();
      delete reference._tippy;
      instance.state.isDestroyed = true;
      invokeHook('onDestroy', [instance]);
    }
  }

  function tippy(targets, optionalProps) {
    if (optionalProps === void 0) {
      optionalProps = {};
    }

    let plugins = defaultProps.plugins.concat(optionalProps.plugins || []);
    /* istanbul ignore else */

    {
      validateTargets(targets);
      validateProps(optionalProps, plugins);
    }

    bindGlobalEventListeners();
    let passedProps = Object.assign({}, optionalProps, {
      plugins
    });
    let elements = getArrayOfElements(targets);
    /* istanbul ignore else */

    {
      let isSingleContentElement = isElement(passedProps.content);
      let isMoreThanOneReferenceElement = elements.length > 1;
      warnWhen(isSingleContentElement && isMoreThanOneReferenceElement, ['tippy() was passed an Element as the `content` prop, but more than', 'one tippy instance was created by this invocation. This means the', 'content element will only be appended to the last tippy instance.', '\n\n', 'Instead, pass the .innerHTML of the element, or use a function that', 'returns a cloned version of the element instead.', '\n\n', '1) content: element.innerHTML\n', '2) content: () => element.cloneNode(true)'].join(' '));
    }

    let instances = elements.reduce(function (acc, reference) {
      let instance = reference && createTippy(reference, passedProps);

      if (instance) {
        acc.push(instance);
      }

      return acc;
    }, []);
    return isElement(targets) ? instances[0] : instances;
  }

  tippy.defaultProps = defaultProps;
  tippy.setDefaultProps = setDefaultProps;
  tippy.currentInput = currentInput;
  let hideAll = function hideAll(_temp) {
    let _ref = _temp === void 0 ? {} : _temp,
        excludedReferenceOrInstance = _ref.exclude,
        duration = _ref.duration;

    mountedInstances.forEach(function (instance) {
      let isExcluded = false;

      if (excludedReferenceOrInstance) {
        isExcluded = isReferenceElement(excludedReferenceOrInstance) ? instance.reference === excludedReferenceOrInstance : instance.popper === excludedReferenceOrInstance.popper;
      }

      if (!isExcluded) {
        let originalDuration = instance.props.duration;
        instance.setProps({
          duration
        });
        instance.hide();

        if (!instance.state.isDestroyed) {
          instance.setProps({
            duration: originalDuration
          });
        }
      }
    });
  };

  // every time the popper is destroyed (i.e. a new target), removing the styles
  // and causing transitions to break for singletons when the console is open, but
  // most notably for non-transform styles being used, `gpuAcceleration: false`.

  let applyStylesModifier = Object.assign({}, core.applyStyles, {
    effect: function effect(_ref) {
      let state = _ref.state;
      let initialStyles = {
        popper: {
          position: state.options.strategy,
          left: '0',
          top: '0',
          margin: '0'
        },
        arrow: {
          position: 'absolute'
        },
        reference: {}
      };
      Object.assign(state.elements.popper.style, initialStyles.popper);
      state.styles = initialStyles;

      if (state.elements.arrow) {
        Object.assign(state.elements.arrow.style, initialStyles.arrow);
      } // intentionally return no cleanup function
      // return () => { ... }

    }
  });

  let createSingleton = function createSingleton(tippyInstances, optionalProps) {
    let _optionalProps$popper;

    if (optionalProps === void 0) {
      optionalProps = {};
    }

    /* istanbul ignore else */
    {
      errorWhen(!Array.isArray(tippyInstances), ['The first argument passed to createSingleton() must be an array of', 'tippy instances. The passed value was', String(tippyInstances)].join(' '));
    }

    let individualInstances = tippyInstances;
    let references = [];
    let triggerTargets = [];
    let currentTarget;
    let overrides = optionalProps.overrides;
    let interceptSetPropsCleanups = [];
    let shownOnCreate = false;

    function setTriggerTargets() {
      triggerTargets = individualInstances.map(function (instance) {
        return normalizeToArray(instance.props.triggerTarget || instance.reference);
      }).reduce(function (acc, item) {
        return acc.concat(item);
      }, []);
    }

    function setReferences() {
      references = individualInstances.map(function (instance) {
        return instance.reference;
      });
    }

    function enableInstances(isEnabled) {
      individualInstances.forEach(function (instance) {
        if (isEnabled) {
          instance.enable();
        } else {
          instance.disable();
        }
      });
    }

    function interceptSetProps(singleton) {
      return individualInstances.map(function (instance) {
        let originalSetProps = instance.setProps;

        instance.setProps = function (props) {
          originalSetProps(props);

          if (instance.reference === currentTarget) {
            singleton.setProps(props);
          }
        };

        return function () {
          instance.setProps = originalSetProps;
        };
      });
    } // have to pass singleton, as it maybe undefined on first call


    function prepareInstance(singleton, target) {
      let index = triggerTargets.indexOf(target); // bail-out

      if (target === currentTarget) {
        return;
      }

      currentTarget = target;
      let overrideProps = (overrides || []).concat('content').reduce(function (acc, prop) {
        acc[prop] = individualInstances[index].props[prop];
        return acc;
      }, {});
      singleton.setProps(Object.assign({}, overrideProps, {
        getReferenceClientRect: typeof overrideProps.getReferenceClientRect === 'function' ? overrideProps.getReferenceClientRect : function () {
          let _references$index;

          return (_references$index = references[index]) == null ? void 0 : _references$index.getBoundingClientRect();
        }
      }));
    }

    enableInstances(false);
    setReferences();
    setTriggerTargets();
    let plugin = {
      fn: function fn() {
        return {
          onDestroy: function onDestroy() {
            enableInstances(true);
          },
          onHidden: function onHidden() {
            currentTarget = null;
          },
          onClickOutside: function onClickOutside(instance) {
            if (instance.props.showOnCreate && !shownOnCreate) {
              shownOnCreate = true;
              currentTarget = null;
            }
          },
          onShow: function onShow(instance) {
            if (instance.props.showOnCreate && !shownOnCreate) {
              shownOnCreate = true;
              prepareInstance(instance, references[0]);
            }
          },
          onTrigger: function onTrigger(instance, event) {
            prepareInstance(instance, event.currentTarget);
          }
        };
      }
    };
    let singleton = tippy(div(), Object.assign({}, removeProperties(optionalProps, ['overrides']), {
      plugins: [plugin].concat(optionalProps.plugins || []),
      triggerTarget: triggerTargets,
      popperOptions: Object.assign({}, optionalProps.popperOptions, {
        modifiers: [].concat(((_optionalProps$popper = optionalProps.popperOptions) == null ? void 0 : _optionalProps$popper.modifiers) || [], [applyStylesModifier])
      })
    }));
    let originalShow = singleton.show;

    singleton.show = function (target) {
      originalShow(); // first time, showOnCreate or programmatic call with no params
      // default to showing first instance

      if (!currentTarget && target == null) {
        return prepareInstance(singleton, references[0]);
      } // triggered from event (do nothing as prepareInstance already called by onTrigger)
      // programmatic call with no params when already visible (do nothing again)


      if (currentTarget && target == null) {
        return;
      } // target is index of instance


      if (typeof target === 'number') {
        return references[target] && prepareInstance(singleton, references[target]);
      } // target is a child tippy instance


      if (individualInstances.indexOf(target) >= 0) {
        let ref = target.reference;
        return prepareInstance(singleton, ref);
      } // target is a ReferenceElement


      if (references.indexOf(target) >= 0) {
        return prepareInstance(singleton, target);
      }
    };

    singleton.showNext = function () {
      let first = references[0];

      if (!currentTarget) {
        return singleton.show(0);
      }

      let index = references.indexOf(currentTarget);
      singleton.show(references[index + 1] || first);
    };

    singleton.showPrevious = function () {
      let last = references[references.length - 1];

      if (!currentTarget) {
        return singleton.show(last);
      }

      let index = references.indexOf(currentTarget);
      let target = references[index - 1] || last;
      singleton.show(target);
    };

    let originalSetProps = singleton.setProps;

    singleton.setProps = function (props) {
      overrides = props.overrides || overrides;
      originalSetProps(props);
    };

    singleton.setInstances = function (nextInstances) {
      enableInstances(true);
      interceptSetPropsCleanups.forEach(function (fn) {
        return fn();
      });
      individualInstances = nextInstances;
      enableInstances(false);
      setReferences();
      setTriggerTargets();
      interceptSetPropsCleanups = interceptSetProps(singleton);
      singleton.setProps({
        triggerTarget: triggerTargets
      });
    };

    interceptSetPropsCleanups = interceptSetProps(singleton);
    return singleton;
  };

  let BUBBLING_EVENTS_MAP = {
    mouseover: 'mouseenter',
    focusin: 'focus',
    click: 'click'
  };
  /**
   * Creates a delegate instance that controls the creation of tippy instances
   * for child elements (`target` CSS selector).
   */

  function delegate(targets, props) {
    /* istanbul ignore else */
    {
      errorWhen(!(props && props.target), ['You must specity a `target` prop indicating a CSS selector string matching', 'the target elements that should receive a tippy.'].join(' '));
    }

    let listeners = [];
    let childTippyInstances = [];
    let disabled = false;
    let target = props.target;
    let nativeProps = removeProperties(props, ['target']);
    let parentProps = Object.assign({}, nativeProps, {
      trigger: 'manual',
      touch: false
    });
    let childProps = Object.assign({
      touch: defaultProps.touch
    }, nativeProps, {
      showOnCreate: true
    });
    let returnValue = tippy(targets, parentProps);
    let normalizedReturnValue = normalizeToArray(returnValue);

    function onTrigger(event) {
      if (!event.target || disabled) {
        return;
      }

      let targetNode = event.target.closest(target);

      if (!targetNode) {
        return;
      } // Get relevant trigger with fallbacks:
      // 1. Check `data-tippy-trigger` attribute on target node
      // 2. Fallback to `trigger` passed to `delegate()`
      // 3. Fallback to `defaultProps.trigger`


      let trigger = targetNode.getAttribute('data-tippy-trigger') || props.trigger || defaultProps.trigger; // @ts-ignore

      if (targetNode._tippy) {
        return;
      }

      if (event.type === 'touchstart' && typeof childProps.touch === 'boolean') {
        return;
      }

      if (event.type !== 'touchstart' && trigger.indexOf(BUBBLING_EVENTS_MAP[event.type]) < 0) {
        return;
      }

      let instance = tippy(targetNode, childProps);

      if (instance) {
        childTippyInstances = childTippyInstances.concat(instance);
      }
    }

    function on(node, eventType, handler, options) {
      if (options === void 0) {
        options = false;
      }

      node.addEventListener(eventType, handler, options);
      listeners.push({
        node,
        eventType,
        handler,
        options
      });
    }

    function addEventListeners(instance) {
      let reference = instance.reference;
      on(reference, 'touchstart', onTrigger, TOUCH_OPTIONS);
      on(reference, 'mouseover', onTrigger);
      on(reference, 'focusin', onTrigger);
      on(reference, 'click', onTrigger);
    }

    function removeEventListeners() {
      listeners.forEach(function (_ref) {
        let node = _ref.node,
            eventType = _ref.eventType,
            handler = _ref.handler,
            options = _ref.options;
        node.removeEventListener(eventType, handler, options);
      });
      listeners = [];
    }

    function applyMutations(instance) {
      let originalDestroy = instance.destroy;
      let originalEnable = instance.enable;
      let originalDisable = instance.disable;

      instance.destroy = function (shouldDestroyChildInstances) {
        if (shouldDestroyChildInstances === void 0) {
          shouldDestroyChildInstances = true;
        }

        if (shouldDestroyChildInstances) {
          childTippyInstances.forEach(function (instance) {
            instance.destroy();
          });
        }

        childTippyInstances = [];
        removeEventListeners();
        originalDestroy();
      };

      instance.enable = function () {
        originalEnable();
        childTippyInstances.forEach(function (instance) {
          return instance.enable();
        });
        disabled = false;
      };

      instance.disable = function () {
        originalDisable();
        childTippyInstances.forEach(function (instance) {
          return instance.disable();
        });
        disabled = true;
      };

      addEventListeners(instance);
    }

    normalizedReturnValue.forEach(applyMutations);
    return returnValue;
  }

  let animateFill = {
    name: 'animateFill',
    defaultValue: false,
    fn: function fn(instance) {
      let _instance$props$rende;

      // @ts-ignore
      if (!((_instance$props$rende = instance.props.render) != null && _instance$props$rende.$$tippy)) {
        {
          errorWhen(instance.props.animateFill, 'The `animateFill` plugin requires the default render function.');
        }

        return {};
      }

      let _getChildren = getChildren(instance.popper),
          box = _getChildren.box,
          content = _getChildren.content;

      let backdrop = instance.props.animateFill ? createBackdropElement() : null;
      return {
        onCreate: function onCreate() {
          if (backdrop) {
            box.insertBefore(backdrop, box.firstElementChild);
            box.setAttribute('data-animatefill', '');
            box.style.overflow = 'hidden';
            instance.setProps({
              arrow: false,
              animation: 'shift-away'
            });
          }
        },
        onMount: function onMount() {
          if (backdrop) {
            let transitionDuration = box.style.transitionDuration;
            let duration = Number(transitionDuration.replace('ms', '')); // The content should fade in after the backdrop has mostly filled the
            // tooltip element. `clip-path` is the other alternative but is not
            // well-supported and is buggy on some devices.

            content.style.transitionDelay = Math.round(duration / 10) + "ms";
            backdrop.style.transitionDuration = transitionDuration;
            setVisibilityState([backdrop], 'visible');
          }
        },
        onShow: function onShow() {
          if (backdrop) {
            backdrop.style.transitionDuration = '0ms';
          }
        },
        onHide: function onHide() {
          if (backdrop) {
            setVisibilityState([backdrop], 'hidden');
          }
        }
      };
    }
  };

  function createBackdropElement() {
    let backdrop = div();
    backdrop.className = BACKDROP_CLASS;
    setVisibilityState([backdrop], 'hidden');
    return backdrop;
  }

  let mouseCoords = {
    clientX: 0,
    clientY: 0
  };
  let activeInstances = [];

  function storeMouseCoords(_ref) {
    let clientX = _ref.clientX,
        clientY = _ref.clientY;
    mouseCoords = {
      clientX,
      clientY
    };
  }

  function addMouseCoordsListener(doc) {
    doc.addEventListener('mousemove', storeMouseCoords);
  }

  function removeMouseCoordsListener(doc) {
    doc.removeEventListener('mousemove', storeMouseCoords);
  }

  let followCursor = {
    name: 'followCursor',
    defaultValue: false,
    fn: function fn(instance) {
      let reference = instance.reference;
      let doc = getOwnerDocument(instance.props.triggerTarget || reference);
      let isInternalUpdate = false;
      let wasFocusEvent = false;
      let isUnmounted = true;
      let prevProps = instance.props;

      function getIsInitialBehavior() {
        return instance.props.followCursor === 'initial' && instance.state.isVisible;
      }

      function addListener() {
        doc.addEventListener('mousemove', onMouseMove);
      }

      function removeListener() {
        doc.removeEventListener('mousemove', onMouseMove);
      }

      function unsetGetReferenceClientRect() {
        isInternalUpdate = true;
        instance.setProps({
          getReferenceClientRect: null
        });
        isInternalUpdate = false;
      }

      function onMouseMove(event) {
        // If the instance is interactive, avoid updating the position unless it's
        // over the reference element
        let isCursorOverReference = event.target ? reference.contains(event.target) : true;
        let followCursor = instance.props.followCursor;
        let clientX = event.clientX,
            clientY = event.clientY;
        let rect = reference.getBoundingClientRect();
        let relativeX = clientX - rect.left;
        let relativeY = clientY - rect.top;

        if (isCursorOverReference || !instance.props.interactive) {
          instance.setProps({
            // @ts-ignore - unneeded DOMRect properties
            getReferenceClientRect: function getReferenceClientRect() {
              let rect = reference.getBoundingClientRect();
              let x = clientX;
              let y = clientY;

              if (followCursor === 'initial') {
                x = rect.left + relativeX;
                y = rect.top + relativeY;
              }

              let top = followCursor === 'horizontal' ? rect.top : y;
              let right = followCursor === 'vertical' ? rect.right : x;
              let bottom = followCursor === 'horizontal' ? rect.bottom : y;
              let left = followCursor === 'vertical' ? rect.left : x;
              return {
                width: right - left,
                height: bottom - top,
                top,
                right,
                bottom,
                left
              };
            }
          });
        }
      }

      function create() {
        if (instance.props.followCursor) {
          activeInstances.push({
            instance,
            doc
          });
          addMouseCoordsListener(doc);
        }
      }

      function destroy() {
        activeInstances = activeInstances.filter(function (data) {
          return data.instance !== instance;
        });

        if (activeInstances.filter(function (data) {
          return data.doc === doc;
        }).length === 0) {
          removeMouseCoordsListener(doc);
        }
      }

      return {
        onCreate: create,
        onDestroy: destroy,
        onBeforeUpdate: function onBeforeUpdate() {
          prevProps = instance.props;
        },
        onAfterUpdate: function onAfterUpdate(_, _ref2) {
          let followCursor = _ref2.followCursor;

          if (isInternalUpdate) {
            return;
          }

          if (followCursor !== undefined && prevProps.followCursor !== followCursor) {
            destroy();

            if (followCursor) {
              create();

              if (instance.state.isMounted && !wasFocusEvent && !getIsInitialBehavior()) {
                addListener();
              }
            } else {
              removeListener();
              unsetGetReferenceClientRect();
            }
          }
        },
        onMount: function onMount() {
          if (instance.props.followCursor && !wasFocusEvent) {
            if (isUnmounted) {
              onMouseMove(mouseCoords);
              isUnmounted = false;
            }

            if (!getIsInitialBehavior()) {
              addListener();
            }
          }
        },
        onTrigger: function onTrigger(_, event) {
          if (isMouseEvent(event)) {
            mouseCoords = {
              clientX: event.clientX,
              clientY: event.clientY
            };
          }

          wasFocusEvent = event.type === 'focus';
        },
        onHidden: function onHidden() {
          if (instance.props.followCursor) {
            unsetGetReferenceClientRect();
            removeListener();
            isUnmounted = true;
          }
        }
      };
    }
  };

  function getProps(props, modifier) {
    let _props$popperOptions;

    return {
      popperOptions: Object.assign({}, props.popperOptions, {
        modifiers: [].concat((((_props$popperOptions = props.popperOptions) == null ? void 0 : _props$popperOptions.modifiers) || []).filter(function (_ref) {
          let name = _ref.name;
          return name !== modifier.name;
        }), [modifier])
      })
    };
  }

  let inlinePositioning = {
    name: 'inlinePositioning',
    defaultValue: false,
    fn: function fn(instance) {
      let reference = instance.reference;

      function isEnabled() {
        return !!instance.props.inlinePositioning;
      }

      let placement;
      let cursorRectIndex = -1;
      let isInternalUpdate = false;
      let triedPlacements = [];
      let modifier = {
        name: 'tippyInlinePositioning',
        enabled: true,
        phase: 'afterWrite',
        fn: function fn(_ref2) {
          let state = _ref2.state;

          if (isEnabled()) {
            if (triedPlacements.indexOf(state.placement) !== -1) {
              triedPlacements = [];
            }

            if (placement !== state.placement && triedPlacements.indexOf(state.placement) === -1) {
              triedPlacements.push(state.placement);
              instance.setProps({
                // @ts-ignore - unneeded DOMRect properties
                getReferenceClientRect: function getReferenceClientRect() {
                  return _getReferenceClientRect(state.placement);
                }
              });
            }

            placement = state.placement;
          }
        }
      };

      function _getReferenceClientRect(placement) {
        return getInlineBoundingClientRect(getBasePlacement(placement), reference.getBoundingClientRect(), arrayFrom(reference.getClientRects()), cursorRectIndex);
      }

      function setInternalProps(partialProps) {
        isInternalUpdate = true;
        instance.setProps(partialProps);
        isInternalUpdate = false;
      }

      function addModifier() {
        if (!isInternalUpdate) {
          setInternalProps(getProps(instance.props, modifier));
        }
      }

      return {
        onCreate: addModifier,
        onAfterUpdate: addModifier,
        onTrigger: function onTrigger(_, event) {
          if (isMouseEvent(event)) {
            let rects = arrayFrom(instance.reference.getClientRects());
            let cursorRect = rects.find(function (rect) {
              return rect.left - 2 <= event.clientX && rect.right + 2 >= event.clientX && rect.top - 2 <= event.clientY && rect.bottom + 2 >= event.clientY;
            });
            let index = rects.indexOf(cursorRect);
            cursorRectIndex = index > -1 ? index : cursorRectIndex;
          }
        },
        onHidden: function onHidden() {
          cursorRectIndex = -1;
        }
      };
    }
  };
  function getInlineBoundingClientRect(currentBasePlacement, boundingRect, clientRects, cursorRectIndex) {
    // Not an inline element, or placement is not yet known
    if (clientRects.length < 2 || currentBasePlacement === null) {
      return boundingRect;
    } // There are two rects and they are disjoined


    if (clientRects.length === 2 && cursorRectIndex >= 0 && clientRects[0].left > clientRects[1].right) {
      return clientRects[cursorRectIndex] || boundingRect;
    }

    switch (currentBasePlacement) {
      case 'top':
      case 'bottom':
        {
          let firstRect = clientRects[0];
          let lastRect = clientRects[clientRects.length - 1];
          let isTop = currentBasePlacement === 'top';
          let top = firstRect.top;
          let bottom = lastRect.bottom;
          let left = isTop ? firstRect.left : lastRect.left;
          let right = isTop ? firstRect.right : lastRect.right;
          let width = right - left;
          let height = bottom - top;
          return {
            top,
            bottom,
            left,
            right,
            width,
            height
          };
        }

      case 'left':
      case 'right':
        {
          let minLeft = Math.min.apply(Math, clientRects.map(function (rects) {
            return rects.left;
          }));
          let maxRight = Math.max.apply(Math, clientRects.map(function (rects) {
            return rects.right;
          }));
          let measureRects = clientRects.filter(function (rect) {
            return currentBasePlacement === 'left' ? rect.left === minLeft : rect.right === maxRight;
          });
          let _top = measureRects[0].top;
          let _bottom = measureRects[measureRects.length - 1].bottom;
          let _left = minLeft;
          let _right = maxRight;

          let _width = _right - _left;

          let _height = _bottom - _top;

          return {
            top: _top,
            bottom: _bottom,
            left: _left,
            right: _right,
            width: _width,
            height: _height
          };
        }

      default:
        {
          return boundingRect;
        }
    }
  }

  let sticky = {
    name: 'sticky',
    defaultValue: false,
    fn: function fn(instance) {
      let reference = instance.reference,
          popper = instance.popper;

      function getReference() {
        return instance.popperInstance ? instance.popperInstance.state.elements.reference : reference;
      }

      function shouldCheck(value) {
        return instance.props.sticky === true || instance.props.sticky === value;
      }

      let prevRefRect = null;
      let prevPopRect = null;

      function updatePosition() {
        let currentRefRect = shouldCheck('reference') ? getReference().getBoundingClientRect() : null;
        let currentPopRect = shouldCheck('popper') ? popper.getBoundingClientRect() : null;

        if (currentRefRect && areRectsDifferent(prevRefRect, currentRefRect) || currentPopRect && areRectsDifferent(prevPopRect, currentPopRect)) {
          if (instance.popperInstance) {
            instance.popperInstance.update();
          }
        }

        prevRefRect = currentRefRect;
        prevPopRect = currentPopRect;

        if (instance.state.isMounted) {
          requestAnimationFrame(updatePosition);
        }
      }

      return {
        onMount: function onMount() {
          if (instance.props.sticky) {
            updatePosition();
          }
        }
      };
    }
  };

  function areRectsDifferent(rectA, rectB) {
    if (rectA && rectB) {
      return rectA.top !== rectB.top || rectA.right !== rectB.right || rectA.bottom !== rectB.bottom || rectA.left !== rectB.left;
    }

    return true;
  }

  tippy.setDefaultProps({
    plugins: [animateFill, followCursor, inlinePositioning, sticky],
    render
  });
  tippy.createSingleton = createSingleton;
  tippy.delegate = delegate;
  tippy.hideAll = hideAll;
  tippy.roundArrow = ROUND_ARROW;

  return tippy;

}));
//# sourceMappingURL=/tippy.umd.js.map
