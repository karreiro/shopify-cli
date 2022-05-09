(function() {

  const sectionTypes = [];
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
}());
