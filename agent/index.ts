Java.perform(() => {
    console.log("[blockheads-patch] agent loaded");

    const NoodleWebViewRun =
        Java.use("com.noodlecake.noodlewebview.NoodleWebView$1")
            .run.overload();

    NoodleWebViewRun.implementation = function () {
        console.log("[blockheads-patch] blocked NoodleWebView run");
        // Deliberately do nothing.
        // This is the original workaround for the WM/WebView freeze.
    };
});
