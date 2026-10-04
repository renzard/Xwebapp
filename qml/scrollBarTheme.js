(function() {
    // Γενικό script, ΟΧΙ βασισμένο σε συγκεκριμένα (obfuscated, συνεχώς
    // μεταβαλλόμενα) CSS class names του X/Twitter - μόνο σταθερά πράγματα:
    // tags, βασική συμπεριφορά σελίδας.

    var css = `
        /* ----- Απόκρυψη scrollbar (πιο "native" εμφάνιση μέσα σε app) ----- */
        ::-webkit-scrollbar {
            -webkit-appearance: none !important;
            width: 0px !important;
            height: 0px !important;
        }

        /* ----- Απόκρυψη του δικού του floating "Post" κουμπιού του X ----- */
        [data-testid="FloatingActionButtons_Tweet_Button"],
        [data-testid="BottomBar"] {
            display: none !important;
        }

        /* ----- Το header με το προφίλ να μένει πάντα ορατό ----- */
        [data-testid="DashButton_ProfileIcon_Link"],
        [data-testid="TopNavBar"] {
            visibility: visible !important;
            opacity: 1 !important;
        }
    `;

    var node = document.createElement("style");
    node.type = "text/css";
    node.appendChild(document.createTextNode(css));
    (document.head || document.documentElement).appendChild(node);

    // ----- EDGE-SWIPE "ΠΙΣΩ" -----
    // Swipe από την αριστερή άκρη -> history.back(), αντίστοιχο με τη native
    // χειρονομία επιστροφής του Ubuntu Touch.
    function enableEdgeSwipeBack() {
        var startX = null;
        var startY = null;
        var EDGE_PX = 24;
        var MIN_DX = 60;

        document.addEventListener("touchstart", function(e) {
            if (e.touches.length !== 1) return;
            var t = e.touches[0];
            if (t.clientX <= EDGE_PX) {
                startX = t.clientX;
                startY = t.clientY;
            } else {
                startX = null;
                startY = null;
            }
        }, { passive: true });

        document.addEventListener("touchend", function(e) {
            if (startX === null) return;
            var t = e.changedTouches[0];
            var dx = t.clientX - startX;
            var dy = Math.abs(t.clientY - startY);
            if (dx > MIN_DX && dy < 60) {
                window.history.back();
            }
            startX = null;
            startY = null;
        }, { passive: true });
    }

    function diagTop() {
        var out = [];
        document.querySelectorAll('body *').forEach(function(e) {
            var r = e.getBoundingClientRect();
            if (r.top >= 0 && r.bottom <= 90 && r.height > 8) {
                var cs = window.getComputedStyle(e);
                if (cs.display === 'none' || cs.visibility === 'hidden' || cs.opacity === '0') {
                    out.push(e.tagName + ':' + (e.getAttribute('data-testid') || '') +
                             ' d=' + cs.display + ' v=' + cs.visibility + ' o=' + cs.opacity);
                }
            }
        });
        console.log('X-DIAG top hidden: ' + out.slice(0, 15).join(' | '));
    }

    function init() {
        setTimeout(diagTop, 5000);
        enableEdgeSwipeBack();
        startObserver();
        scheduleWork(0);
    }


    // ----- ΑΠΟΚΡΥΨΗ ΤΗΣ ΚΑΤΩ ΜΠΑΡΑΣ ΠΛΟΗΓΗΣΗΣ ΤΟΥ X -----
    // Την αντικαθιστά το δικό μας floating "+" μενού. Δεν βασιζόμαστε σε class
    // names (αλλάζουν συνέχεια): ξεκινάμε από τα links πλοήγησης και κρύβουμε
    // το στοιχείο που τα κρατάει, αν είναι κολλημένο κάτω και σχεδόν full-width.
    function isBottomBar(el, maxHeight) {
        var rect = el.getBoundingClientRect();
        if (!(rect.height > 0 && rect.height < maxHeight &&
              rect.bottom >= window.innerHeight - 4 &&
              rect.top > window.innerHeight * 0.5 &&
              rect.width >= window.innerWidth * 0.9)) return false;
        var pos = window.getComputedStyle(el).position;
        return pos === 'fixed' || pos === 'sticky';
    }

    // Στοιχεία του ΠΑΝΩ header (avatar/προφίλ, tabs For you / Following)
    // που ΔΕΝ πρέπει ποτέ να κρυφτούν.
    var PROTECTED = '[data-testid="DashButton_ProfileIcon_Link"], ' +
                    '[data-testid="TopNavBar"], [data-testid="primaryColumn"], ' +
                    '[role="tablist"], header, main';

    function hasInteractiveContent(el) {
        // Ποτέ δεν κρύβουμε composer, πεδία κειμένου ή βίντεο
        return !!el.querySelector('input, textarea, [contenteditable="true"], video') ||
               !!el.querySelector(PROTECTED) || el.matches(PROTECTED);
    }

    function hideBar(el) {
        el.style.setProperty('display', 'none', 'important');
        el.dataset.bottomNavHidden = '1';
    }

    function hideBottomNav() {
        var seeds = document.querySelectorAll(
            'a[href="/explore"], a[href="/notifications"], a[href="/messages"]'
        );
        seeds.forEach(function(seed) {
            var el = seed.parentElement, depth = 0;
            while (el && el !== document.body && depth < 15) {
                if (el.dataset && el.dataset.bottomNavHidden === '1') return;
                var pos = window.getComputedStyle(el).position;
                if (pos === 'fixed' || pos === 'sticky') {
                    var r = el.getBoundingClientRect();
                    if (r.height > 0 && r.height < 200 &&
                        r.top > window.innerHeight * 0.5 &&
                        r.width >= window.innerWidth * 0.9 &&
                        !hasInteractiveContent(el) &&
                        el.querySelectorAll('a[href]').length >= 3) {
                        hideBar(el);
                        console.log('X-HIDE bottom ' + el.tagName + ' testid=' +
                            el.getAttribute('data-testid') + ' top=' + Math.round(r.top) +
                            ' h=' + Math.round(r.height) + ' ih=' + window.innerHeight);
                        return;
                    }
                }
                el = el.parentElement;
                depth++;
            }
        });
    }

    // Fallback, αν το data-testid αλλάξει: ένα μικρό link προς /compose/post
    // κολλημένο κάτω δεξιά είναι το floating κουμπί του X. Το κρύβουμε με
    // display:none, ώστε το δικό μας "Post" να μπορεί ακόμα να το πατήσει (click()).
    function hideFloatingPost() {
        document.querySelectorAll('a[href="/compose/post"]').forEach(function(a) {
            var r = a.getBoundingClientRect();
            if (r.width > 0 && r.width < 120 && r.height < 120 &&
                r.right > window.innerWidth * 0.6 &&
                r.bottom > window.innerHeight * 0.5) {
                a.style.setProperty('display', 'none', 'important');
            }
        });
    }

    function restoreHeader() {
        document.querySelectorAll('[data-bottom-nav-hidden="1"]').forEach(function(el) {
            if (el.matches(PROTECTED) || el.querySelector(PROTECTED)) {
                el.style.removeProperty('display');
                delete el.dataset.bottomNavHidden;
            }
        });
    }

    var workTimer = null;
    function scheduleWork(delay) {
        if (workTimer) return;
        workTimer = setTimeout(function() {
            workTimer = null;
            if (document.visibilityState !== "visible" || !document.body) return;
            restoreHeader();
            hideBottomNav();
            hideFloatingPost();
        }, delay || 150);
    }

    function startObserver() {
        if (!window.MutationObserver) return;
        new MutationObserver(function() { scheduleWork(150); })
            .observe(document.documentElement, { childList: true, subtree: true });
    }

    // Πλοήγηση από το floating μενού (καλείται από το Main.qml). Πατάμε τα ίδια
    // τα links του X ώστε η αλλαγή σελίδας να γίνεται μέσα στην εφαρμογή (SPA).
    // Αν δεν βρεθεί το link, πέφτουμε σε κανονική φόρτωση της διεύθυνσης.
    window.__xGo = function(key) {
        var selectors = {
            home:    ['a[href="/home"]'],
            explore: ['a[href="/explore"]'],
            notifs:  ['a[href="/notifications"]'],
            inbox:   ['a[href="/messages"]'],
            post:    ['a[href="/compose/post"]', '[data-testid="FloatingActionButtons_Tweet_Button"]']
        };
        var urls = {
            home: '/home', explore: '/explore', notifs: '/notifications',
            inbox: '/messages', post: '/compose/post'
        };
        var list = selectors[key] || [];
        var el = null;
        for (var i = 0; i < list.length && !el; i++) {
            el = document.querySelector(list[i]);
        }
        if (el) {
            (el.closest('a, button, div[role="button"]') || el).click();
        } else if (urls[key]) {
            window.location.assign(urls[key]);
        }
    };

    // Το X είναι SPA: ακούμε και τις αλλαγές διεύθυνσης (pushState)
    (function() {
        var _push = history.pushState, _replace = history.replaceState;
        history.pushState = function() { var r = _push.apply(this, arguments); scheduleWork(30); return r; };
        history.replaceState = function() { var r = _replace.apply(this, arguments); scheduleWork(30); return r; };
        window.addEventListener('popstate', function() { scheduleWork(30); });
    })();

    // Safety-net, σε περίπτωση που κάτι αλλάξει χωρίς mutation
    setInterval(function() { scheduleWork(0); }, 2500);

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", init);
    } else {
        init();
    }
})();
