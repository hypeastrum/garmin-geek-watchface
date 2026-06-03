import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class GeekWatchFaceView extends WatchUi.WatchFace {

    private const COLOR_WARM = 0xFFDD99;

    private var _data as DataProvider;
    private var _showSeconds as Boolean = true;

    function initialize() {
        WatchFace.initialize();
        _data = new DataProvider();
    }

    function onLayout(dc as Dc) as Void {
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(COLOR_WARM, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var leftAreaW = (w * 0.6).toNumber();

        // --- Time ---
        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var hours = now.hour != null ? now.hour as Number : 0;
        var minutes = now.min != null ? now.min as Number : 0;
        var seconds = (_showSeconds && now.sec != null) ? now.sec as Number : null;

        var settings = System.getDeviceSettings();
        if (!settings.is24Hour && hours > 12) {
            hours -= 12;
        } else if (!settings.is24Hour && hours == 0) {
            hours = 12;
        }

        var widthFactor = (seconds != null) ? 3.85 : 2.7;
        var maxByWidth = leftAreaW.toFloat() / widthFactor;
        var maxByHeight = h * 0.32;
        var baseDigitH = maxByWidth < maxByHeight ? maxByWidth : maxByHeight;

        var digitH = (baseDigitH * 1.5).toNumber();
        var digitW = (digitH * 0.50).toNumber();
        var thickness = (digitH * 0.12).toNumber();
        if (thickness < 2) { thickness = 2; }
        var gap = (digitW * 0.25).toNumber();
        var colonSize = thickness + 1;

        var secDigitH = (baseDigitH * 0.65 / 1.5).toNumber();
        var secDigitW = (baseDigitH * 0.30 / 1.5).toNumber();
        var secThickness = (baseDigitH * 0.078 / 1.5).toNumber();
        if (secThickness < 1) { secThickness = 1; }
        var sColonSize = secThickness + 1;

        var dateFont = _pickFontForHeight(dc, secDigitH);
        var dateFontH = dc.getFontHeight(dateFont);
        var dateStr = "";
        var dateW = 0;
        if (seconds != null) {
            var monthNames = ["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"];
            var monthIdx = (now.month != null ? (now.month as Number) : 1) - 1;
            if (monthIdx < 0) { monthIdx = 0; }
            if (monthIdx > 11) { monthIdx = 11; }
            var dayN = now.day != null ? (now.day as Number) : 1;
            dateStr = " " + _pad2(dayN) + monthNames[monthIdx];
            dateW = dc.getTextWidthInPixels(dateStr, dateFont);
        }

        var timeW = 4 * digitW + 4 * gap + colonSize;
        if (seconds != null) {
            timeW += gap + sColonSize + gap + secDigitW + gap + secDigitW + dateW;
        }

        var timeX = leftAreaW / 2 - timeW / 2;
        if (timeX < 4) { timeX = 4; }
        var timeY = (h - digitH) / 2;

        SegmentRenderer.drawTime(dc, hours, minutes, seconds,
                                 timeX, timeY,
                                 digitW, digitH, thickness, gap,
                                 COLOR_WARM,
                                 secDigitW, secDigitH, secThickness);

        if (seconds != null && dateStr.length() > 0) {
            var secEndX = timeX + 4 * digitW + 4 * gap + colonSize
                          + gap + sColonSize + gap + secDigitW + gap + secDigitW;
            var secY = timeY + digitH - secDigitH;
            var dateY = secY + (secDigitH - dateFontH) / 2;
            dc.setColor(COLOR_WARM, Graphics.COLOR_TRANSPARENT);
            dc.drawText(secEndX, dateY, dateFont, dateStr, Graphics.TEXT_JUSTIFY_LEFT);
        }

        // --- Arc items ---
        var topItems = [
            _formatSunRange(),
            _formatAlt(),
            _formatWeather(),
            _formatSensorTemp(),
            _formatBattery()
        ] as Array<String>;

        var bottomItems = [
            _formatHr(),
            _formatStress(),
            _formatBodyBattery(),
            _formatSteps()
        ] as Array<String>;

        _drawArc(dc, w, h, topItems, 210.0, 330.0);
        _drawArc(dc, w, h, bottomItems, 150.0, 30.0);
    }

    private function _drawArc(dc as Dc, w as Number, h as Number,
                              items as Array<String>,
                              startDeg as Float, endDeg as Float) as Void {
        var font = Graphics.FONT_XTINY;
        var cx = w / 2;
        var cy = h / 2;
        var r = (w / 2) - 12;
        var n = items.size();
        if (n == 0) { return; }

        var step = (n > 1) ? (endDeg - startDeg) / (n - 1) : 0;
        dc.setColor(COLOR_WARM, Graphics.COLOR_TRANSPARENT);

        for (var i = 0; i < n; i++) {
            var deg = startDeg + i * step;
            var rad = deg * Math.PI / 180.0;
            var ix = cx + (r * Math.cos(rad)).toNumber();
            var iy = cy + (r * Math.sin(rad)).toNumber();

            // Align text away from the nearest edge.
            var horiz;
            if (ix < cx - 30) {
                horiz = Graphics.TEXT_JUSTIFY_LEFT;
            } else if (ix > cx + 30) {
                horiz = Graphics.TEXT_JUSTIFY_RIGHT;
            } else {
                horiz = Graphics.TEXT_JUSTIFY_CENTER;
            }

            dc.drawText(ix, iy, font, items[i],
                horiz | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // --- formatters ---

    private function _formatSunRange() as String {
        var sr = _data.getSunrise();
        var ss = _data.getSunset();
        var result = "";
        if (sr != null) {
            var i = Gregorian.info(sr, Time.FORMAT_SHORT);
            result += _pad2(i.hour != null ? i.hour as Number : 0) + ":" +
                      _pad2(i.min != null ? i.min as Number : 0);
        } else {
            result += "--:--";
        }
        result += "-";
        if (ss != null) {
            var i2 = Gregorian.info(ss, Time.FORMAT_SHORT);
            result += _pad2(i2.hour != null ? i2.hour as Number : 0) + ":" +
                      _pad2(i2.min != null ? i2.min as Number : 0);
        } else {
            result += "--:--";
        }
        return result;
    }

    private function _formatAlt() as String {
        var alt = _data.getAltitude();
        return alt != null ? alt.toString() + "m" : "--m";
    }

    private function _formatWeather() as String {
        var cur = _data.getCurrentTemp();
        return cur != null ? "W " + cur.toString() + "°" : "W --°";
    }

    private function _formatSensorTemp() as String {
        var t = _data.getSensorTemp();
        if (t == null) { return "T --°"; }
        return "T " + t.toNumber().toString() + "°";
    }

    private function _formatBattery() as String {
        var pct = System.getSystemStats().battery;
        return pct.format("%d") + "%";
    }

    private function _formatHr() as String {
        var hr = _data.getHeartRate();
        return "HR " + (hr != null ? hr.toString() : "--");
    }

    private function _formatStress() as String {
        var s = _data.getStress();
        return "STR " + (s != null ? s.toString() : "--");
    }

    private function _formatBodyBattery() as String {
        var bb = _data.getBodyBattery();
        return "BB " + (bb != null ? bb.toString() : "--");
    }

    private function _formatSteps() as String {
        var s = _data.getSteps();
        var g = _data.getStepGoal();
        return (s != null ? s.toString() : "--") + "/" +
               (g != null ? g.toString() : "--");
    }

    function onEnterSleep() as Void {
        _showSeconds = false;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        _showSeconds = true;
        WatchUi.requestUpdate();
    }

    private function _pad2(val as Number) as String {
        if (val < 10) {
            return "0" + val.toString();
        }
        return val.toString();
    }

    private function _pickFontForHeight(dc as Dc, targetH as Number) as FontType {
        var fonts = [Graphics.FONT_XTINY, Graphics.FONT_TINY,
                     Graphics.FONT_SMALL, Graphics.FONT_MEDIUM] as Array<FontType>;
        var best = Graphics.FONT_XTINY;
        var bestH = dc.getFontHeight(best);
        for (var i = 1; i < fonts.size(); i++) {
            var fh = dc.getFontHeight(fonts[i]);
            if (fh <= targetH && fh > bestH) {
                best = fonts[i];
                bestH = fh;
            }
        }
        return best;
    }
}
