console.log("example.js loaded")

simple()

/*
test(1, 2, 3).then(function (res) {
  console.log(res)
}).catch(function (err) {
  console.error("Error!", err)
})
*/

// setInterval(test, 100)

// window.onbeforeunload = function(e){e.preventDefault();console.log("before unload");}

window.addEventListener('DOMContentLoaded', function () {
  document.addEventListener('click', function (e) {
  	if (e.target.href) {
      e.preventDefault();
      e.stopPropagation();
      externalNavigate({href: e.target.href, target: e.target.target || "_self"});
      return false;
    }
    return true;
  }, true);
}, false);
