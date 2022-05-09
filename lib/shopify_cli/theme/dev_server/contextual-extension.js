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

  function fetchSection(element) {
    const closestSection = element.closest(".shopify-section");
    const sectionType = fetchSectionTypeById(closestSection.id);

    console.log(`[Contextual Extension] Opening "sections/${sectionType}.liquid"...`)

    return sectionType;
  }

  document.querySelector("body").onclick = (event) => {
    const sectionType = fetchSection(event.target);

    openSection(sectionType);

    event.preventDefault();
    event.stopPropagation();
    event.stopImmediatePropagation();

    return false;
  }
}());
