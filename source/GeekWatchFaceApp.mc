import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class GeekWatchFaceApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as Array<Views or InputDelegates> {
        return [new GeekWatchFaceView()] as Array<Views or InputDelegates>;
    }
}
