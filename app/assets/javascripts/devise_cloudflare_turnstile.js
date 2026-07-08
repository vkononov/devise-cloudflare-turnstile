(function () {
  "use strict";

  function injectAndRenderWidgets() {
    var metaTag = document.querySelector('meta[name="cf-turnstile-site-key"]');
    if (!metaTag || !metaTag.content) return;

    var siteKey = metaTag.content;

    document
      .querySelectorAll('form[method="post"], form[method="POST"]')
      .forEach(function (form) {
        // Skip if form already has an initialized widget
        var existingWidget = form.querySelector("[data-turnstile-injected]");
        if (existingWidget) {
          // Re-render if widget container is empty (e.g., after server re-render)
          if (
            existingWidget.childElementCount === 0 &&
            !existingWidget.dataset.initialized &&
            window.turnstile
          ) {
            window.turnstile.render(existingWidget);
            existingWidget.dataset.initialized = "true";
          }
          return;
        }

        // Find submit button
        var submit = form.querySelector(
          'input[type="submit"], button[type="submit"], button:not([type])'
        );
        if (!submit) return;

        // Create widget container
        var widget = document.createElement("div");
        widget.setAttribute("data-sitekey", siteKey);
        widget.setAttribute("data-turnstile-injected", "true");

        // Insert before submit button
        submit.parentNode.insertBefore(widget, submit);

        // Render the widget
        if (window.turnstile) {
          window.turnstile.render(widget);
          widget.dataset.initialized = "true";
        } else {
          // Turnstile script not loaded yet, add class for implicit rendering
          widget.className = "cf-turnstile";
        }
      });
  }

  // Run on initial page load
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", injectAndRenderWidgets);
  } else {
    injectAndRenderWidgets();
  }

  // Run on Turbo navigation/render
  document.addEventListener("turbo:load", injectAndRenderWidgets);
  document.addEventListener("turbo:render", injectAndRenderWidgets);

  // Handle Turbo Streams
  document.addEventListener("turbo:before-stream-render", function (event) {
    var originalRender = event.detail.render.bind(event.detail);
    event.detail.render = function () {
      originalRender.apply(this, arguments);
      injectAndRenderWidgets();
    };
  });

  // Run on Turbolinks navigation (legacy)
  document.addEventListener("turbolinks:load", injectAndRenderWidgets);
})();
