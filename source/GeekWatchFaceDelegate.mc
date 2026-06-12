import Toybox.Complications;
import Toybox.Lang;
import Toybox.WatchUi;

class GeekWatchFaceDelegate extends WatchUi.WatchFaceDelegate {

    private var _view as GeekWatchFaceView;

    function initialize(view as GeekWatchFaceView) {
        WatchFaceDelegate.initialize();
        _view = view;
    }

    function onPress(clickEvent as WatchUi.ClickEvent) as Lang.Boolean {
        var coords = clickEvent.getCoordinates();
        var compType = _view.hitTest(coords[0], coords[1]);
        if (compType == null) { return false; }
        setSelectedComplication(compType);
        return true;
    }
}
