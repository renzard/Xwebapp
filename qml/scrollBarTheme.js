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

    function init() {
        enableEdgeSwipeBack();
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", init);
    } else {
        init();
    }
})();
