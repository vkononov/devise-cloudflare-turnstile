(function() {
  'use strict';

  var WIDGET_CLASS = 'cf-turnstile';

  function siteKey() {
    var meta = document.querySelector('meta[name="cf-turnstile-site-key"]');

    return meta && meta.content ? meta.content : null;
  }

  function defaultData() {
    var meta = document.querySelector('meta[name="cf-turnstile-default-data"]');

    if (!meta || !meta.content) {
      return {};
    }

    try {
      return JSON.parse(meta.content) || {};
    }
    catch (e) {
      // eslint-disable-next-line no-console
      console.warn('devise-cloudflare-turnstile: invalid default data', e);

      return {};
    }
  }

  function applyDefaultData(widget) {
    var data = defaultData();
    var key;
    var value;

    for (key in data) {
      if (Object.prototype.hasOwnProperty.call(data, key) && key !== 'sitekey') {
        value = data[key];

        if (value !== null && typeof value !== 'undefined') {
          widget.setAttribute('data-' + key, value);
        }
      }
    }
  }

  function renderWidget(widget) {
    if (widget.dataset.initialized || widget.childElementCount > 0) {
      return;
    }

    if (!window.turnstile) {
      return;
    }

    try {
      window.turnstile.render(widget);
      widget.dataset.initialized = 'true';
    }
    catch (e) {
      // eslint-disable-next-line no-console
      console.warn('devise-cloudflare-turnstile: turnstile.render failed', e);
    }
  }

  function injectWidgets() {
    var key = siteKey();
    var forms;
    var form;
    var widget;
    var submit;
    var i;

    if (!key) {
      return;
    }

    forms = document.querySelectorAll('form[method="post"], form[method="POST"]');

    for (i = 0; i < forms.length; i++) {
      form = forms[i];
      widget = form.querySelector('.' + WIDGET_CLASS);

      if (!widget) {
        submit = form.querySelector('input[type="submit"], button[type="submit"], button:not([type])');

        if (!submit) {
          continue;
        }

        widget = document.createElement('div');
        widget.className = WIDGET_CLASS;
        applyDefaultData(widget);
        widget.setAttribute('data-sitekey', key);
        submit.parentNode.insertBefore(widget, submit);
      }

      /*
       * Render here rather than waiting for cloudflare-turnstile-rails:
       * on turbo:render the helper often runs before we inject the widget.
       */
      renderWidget(widget);
    }
  }

  if (window._deviseTurnstileInjectorLoaded) {
    injectWidgets();
  }
  else {
    window._deviseTurnstileInjectorLoaded = true;

    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', injectWidgets);
    }
    else {
      injectWidgets();
    }

    document.addEventListener('turbo:load', injectWidgets);
    document.addEventListener('turbo:render', injectWidgets);
    document.addEventListener('turbolinks:load', injectWidgets);

    /*
     * Same pattern as cloudflare-turnstile-rails: re-run after Turbo Streams
     * replace DOM nodes (e.g. form re-renders).
     */
    document.addEventListener('turbo:before-stream-render', function(event) {
      var originalRender = event.detail.render.bind(event.detail);

      event.detail.render = function() {
        originalRender.apply(this, arguments);
        injectWidgets();
      };
    });
  }
}());
