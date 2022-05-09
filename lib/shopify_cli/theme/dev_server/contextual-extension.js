(function() {

  document.querySelector("body").onclick = () => {
    console.log("Clicked!");

    const body = "file=/Users/karreiro/src/github.com/Shopify/my_theme/sections/cart-icon-bubble.liquid"

    fetch("/contextual-extension", {method: "POST", body: body})
      .then(response => response.json())
      .then(data => console.log(data));
  }

}());
