var listofgigstocome = document.querySelectorAll("ul>li.ns-notpassed");
var nextgig = listofgigstocome[listofgigstocome.length - 1];
if (nextgig) {
  nextgig.classList.add("ns-nextgig");
}

window.addEventListener("load", () => {
  quicklink.listen({
    origins: !0,
    priority: !0,
  });
});

// Lazy load images
window.addEventListener("load", function () {
  var timer, images, viewHeight;

  function init() {
    images = document.body.querySelectorAll("[data-src]");
    viewHeight = Math.max(
      document.documentElement.clientHeight,
      window.innerHeight
    );

    lazyload(0);
  }

  function scroll() {
    lazyload(200);
  }

  function lazyload(delay) {
    if (timer) {
      return;
    }

    timer = setTimeout(function () {
      var changed = false;

      requestAnimationFrame(function () {
        for (var i = 0; i < images.length; i++) {
          var img = images[i];
          var rect = img.getBoundingClientRect();

          if (!(rect.bottom < 0 || rect.top - 100 - viewHeight >= 0)) {
            img.onload = function (e) {
              e.target.className = "loaded";
            };

            img.className = "notloaded";
            img.src = img.getAttribute("data-src");
            img.removeAttribute("data-src");
            changed = true;
          }
        }

        if (changed) {
          filterImages();
        }

        timer = null;
      });
    }, delay);
  }

  function filterImages() {
    images = Array.prototype.filter.call(images, function (img) {
      return img.hasAttribute("data-src");
    });

    if (images.length === 0) {
      window.removeEventListener("scroll", scroll);
      window.removeEventListener("resize", init);
      return;
    }
  }

  // polyfill for older browsers
  window.requestAnimationFrame = (function () {
    return (
      window.requestAnimationFrame ||
      window.webkitRequestAnimationFrame ||
      window.mozRequestAnimationFrame ||
      function (callback) {
        window.setTimeout(callback, 1000 / 60);
      }
    );
  })();

  window.addEventListener("scroll", scroll);
  window.addEventListener("resize", init);

  init();
});

document.addEventListener("DOMContentLoaded", function () {
  // Spin and grow the logo on load
  gsap.fromTo(
    "#site-logo",
    { rotate: 0, scale: 0, opacity: 0 },
    { rotate: 360, scale: 1, opacity: 1, duration: 1.5, ease: "power2.inOut" }
  );

  if (typeof gsap === "undefined" || typeof ScrollTrigger === "undefined")
    return;
  gsap.registerPlugin(ScrollTrigger);

  // Funky effect for the next upcoming gig
  const nextGig = document.querySelector(".ns-nextgig");
  if (nextGig) {
    gsap.from(nextGig, {
      x: 0,
      y: -80,
      opacity: 0,
      scale: 1,
      backgroundColor: "#c62129",
      color: "#fff",
      duration: 1.2,
      ease: "bounce.out",
      scrollTrigger: {
        trigger: nextGig,
        start: "top 70%",
        toggleActions: "play none none none",
      },
      onComplete: () => {
        gsap.to(nextGig, {
          backgroundColor: "",
          color: "",
          duration: 0.5,
        });
      },
    });
  }

  // Fly-in, spinning, for all other gigs except the next gig, line by line as you scroll
  const otherGigs = Array.from(
    document.querySelectorAll(
      "ul>li.gig-item, ul>li.ns-notpassed, ul>li.ns-strikethrough"
    )
  ).filter((item) => !item.classList.contains("ns-nextgig"));

  gsap.fromTo(
    otherGigs,
    {
      y: -200,
      opacity: 0,
      filter: "blur(8px)",
    },
    {
      y: 0,
      opacity: 1,
      filter: "blur(0px)",
      duration: 1,
      ease: "power3.out",
      stagger: 0.2,
      scrollTrigger: {
        trigger: otherGigs[0].parentElement,
        start: "top 70%",
        toggleActions: "play none none none",
      },
    }
  );
});


    // Flip every 3 seconds (rotateY)
    gsap.to(".ns-nextgig", {
      rotateY: 360,
      duration: 3,
      repeat: -1,
      ease: "power2.inOut",
      repeatDelay: 2
    });
