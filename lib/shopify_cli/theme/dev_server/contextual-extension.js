(function() {

  // ===========================================================================
  // inpector

  const sectionTypeByNameIndex = {};

  function sectionNameByType() {
    const namespace = window.__SHOPIFY_CLI_ENV__;
    return namespace.section_names_by_type;
  }

  function isSectionType(value) {
    const namesByType = sectionNameByType();
    return Object.keys(namesByType).indexOf(value) !== -1;
  }

  function sectionTypeByName(name) {
    if (Object.keys(sectionTypeByNameIndex).length === 0) {
      const namesByType = sectionNameByType();
      for(const key in namesByType) {
        const values = [].concat(namesByType[key]) ;
        
        values.forEach((value) => {
          sectionTypeByNameIndex[value] = key;
        });
      }
    }

    return sectionTypeByNameIndex[name];
  }

  function fetchSectionTypeById(id) {
    const sectionSuffix = id.replace(/^shopify-section-/, '').replace(/^.*__/, '');

    if (isSectionType(sectionSuffix)) {
      return sectionSuffix;
    }

    return sectionTypeByName(sectionSuffix) || sectionSuffix;
  }

  function openSection(section) {
    const body = `section=${section}`

    fetch("/contextual-extension", {method: "POST", body: body});
  }

  function blink(element) {
    const originalOpacity = element.style.opacity;
    const originalTransition = element.style.transition;
    const originalFilter = element.style.filter;

    element.style.transition = "all 0.1s"
    element.style.opacity = ".7";
    element.style.filter = "grayscale(.3)"

    setTimeout(() => {
      element.style.transition = originalOpacity;
      element.style.opacity = originalTransition;
      element.style.filter = originalFilter;
    }, 200);
  }

  document.querySelector("body").onkeydown = (event) => {
    if (event.key === "k" && event.shiftKey && event.metaKey) {
      const inspector = document.querySelector("#shopify-cli-inspector");
      inspector.classList.toggle("shopify-cli-expanded");
    }
  }

  document.querySelector("body").onclick = (event) => {
    if (!event.metaKey) {
      return;
    }
    
    const closestSection = event.target.closest(".shopify-section");

    if (!closestSection) {
      return;
    }

    const sectionType = fetchSectionTypeById(closestSection.id);

    if (sectionType) {
      console.log(`[Contextual Extension] Opening "sections/${sectionType}.liquid"...`);

      blink(closestSection);
      openSection(sectionType);
    }

    event.preventDefault();
    event.stopPropagation();
    event.stopImmediatePropagation();

    return false;
  }

  // ===========================================================================
  // theme name

  function updateDevThemeInfo() {
    const store = document.querySelector("#shopify-cli-store");
    const name = document.querySelector("#shopify-cli-theme-name");
    const id = document.querySelector("#shopify-cli-theme-id");

    store.textContent = Shopify.shop;
    name.textContent = Shopify.theme.name;
    id.textContent = Shopify.theme.id;
  }

  // ===========================================================================
  // sections

  function updateSections() {
    const element = document.querySelector("#shopify-cli-sections");
    const liInstances = { get: () => document.createElement("li") };
    const bodySize = document.body.innerHTML.length;

    const sections = [...document.querySelectorAll(".shopify-section")].map((section) => {
      const type = fetchSectionTypeById(section.id);
      const size = section.innerHTML.length;

      return { size, type };
    });

    sections.forEach((section) => {
      // TODO: add anchor
      const li = liInstances.get();
      const pct = (section.size * 100) / bodySize;
      li.textContent = `${section.type}.liquid (${pct.toFixed(2)}%)`;
      li.onclick = () => openSection(section.type);
      element.appendChild(li);
    });
  }

  // ===========================================================================
  // metrics

  const navigationType = "navigation";

  function updatePath() {
    const path = document.querySelector("#shopify-cli-path");
    path.textContent = window.location.pathname;
  }

  function updateLoadingTime() {
    const entries = window.performance.getEntriesByType(navigationType);

    if (entries && entries.length === 1) {
      const entry = entries[0];
      const loadingTimeElement = document.querySelector("#shopify-cli-loading-time");

      // https://developer.mozilla.org/en-US/docs/Web/Performance/Navigation_and_resource_timings/screen_shot_2019-05-03_at_1.06.27_pm.png
      loadingTimeElement.textContent = `${entry.domComplete.toFixed(2)}ms`;
    }
  }

  const observer = new PerformanceObserver(() => {
    updatePath();
    updateLoadingTime();
    updateSections();
    updateDevThemeInfo();
  });

  observer.observe({entryTypes: [navigationType]});
}());
