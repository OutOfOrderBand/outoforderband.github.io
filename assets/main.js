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

// Liquid Morph Reveal Animation - Scroll Triggered
function animateLiquidMorphThumbnails(thumbnails) {
    // Animate to final state with elastic easing
    gsap.to(thumbnails, {
        scaleX: 1,
        scaleY: 1,
        opacity: 1,
        borderRadius: "15px",
        duration: 1.5,
        ease: "elastic.out(1, 0.5)",
        stagger: {
            amount: 0.6,
            from: "center"
        }
    });

    // Optional: Add subtle floating animation after reveal
    gsap.to(thumbnails, {
        y: [0, -10, 0],
        duration: 2,
        ease: "sine.inOut",
        repeat: -1,
        stagger: 0.2,
        delay: 1.5
    });
}

// Set up scroll-triggered animation
function initScrollTriggerThumbnails() {
    const thumbnails = document.querySelectorAll('.video-thumbnail');
    
    // Set initial state for all thumbnails
    gsap.set(thumbnails, { 
        scaleX: 0.1,
        scaleY: 2,
        opacity: 0,
        borderRadius: "50%"
    });

    // Create observer for each thumbnail
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                // Get all thumbnails in the same container as the visible one
                const container = entry.target.closest('.thumbnails-container, .thumbnails-grid, section, div');
                const containerThumbnails = container ? 
                    container.querySelectorAll('.video-thumbnail') : 
                    [entry.target];

                // Animate the group
                animateLiquidMorphThumbnails(containerThumbnails);
                
                // Unobserve all thumbnails in this container to prevent re-triggering
                containerThumbnails.forEach(thumb => observer.unobserve(thumb));
            }
        });
    }, {
        threshold: 0.3,
        rootMargin: '0px 0px -50px 0px'
    });

    // Observe each thumbnail
    thumbnails.forEach(thumbnail => {
        observer.observe(thumbnail);
    });
}

document.addEventListener("DOMContentLoaded", function () {
  // Initialize thumbnail animations
  initScrollTriggerThumbnails();

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

  // Flip every 3 seconds (rotateY)
  gsap.to(".ns-nextgig", {
    rotateY: 360,
    duration: 3,
    repeat: -1,
    ease: "power2.inOut",
    repeatDelay: 2,
  });
});