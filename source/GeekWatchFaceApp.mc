import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class GeekWatchFaceApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as Array<Views or InputDelegates> {
        var view = new GeekWatchFaceView();
        if (WatchUi has :WatchFaceDelegate) {
            return [view, new GeekWatchFaceDelegate(view)] as Array<Views or InputDelegates>;
        }
        return [view] as Array<Views or InputDelegates>;
    }
}
