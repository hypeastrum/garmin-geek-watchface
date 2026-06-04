import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class GeekWatchFaceView extends WatchUi.WatchFace {

    private const COLOR_WARM = 0xFFDD99;
    private const VECTOR_FONT_FACES = [
        "RobotoCondensedRegular", "RobotoRegular", "Roboto", "PridiRegular"
    ] as Array<String>;

    private var _data as DataProvider;
    private var _showSeconds as Boolean = true;
    private var _curvedFont as VectorFont? = null;

    function initialize() {
        WatchFace.initialize();
        _data = new DataProvider();
    }

    function onLayout(dc as Dc) as Void {
        if (Graphics has :getVectorFont) {
            var size = (dc.getHeight() * 0.055).toNumber();
            if (size < 10) { size = 10; }
            for (var i = 0; i < VECTOR_FONT_FACES.size(); i++) {
                var f = Graphics.getVectorFont({:face => VECTOR_FONT_FACES[i], :size => size});
                if (f != null) {
                    _curvedFont = f;
                    break;
                }
            }
        }
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

        var hhmmWidth = 4 * digitW + 4 * gap + colonSize;
        var timeX = leftAreaW / 2 - hhmmWidth / 2;
        if (timeX < 4) { timeX = 4; }
        var timeY = (h - digitH) / 2;

        SegmentRenderer.drawTime(dc, hours, minutes, null,
                                 timeX, timeY,
                                 digitW, digitH, thickness, gap,
                                 COLOR_WARM,
                                 null, null, null);

        // --- Three zones to the right of the minutes ---
        // Each 1/3 of the minute height: seconds+alarm / date / day+weather.
        var rightColX = timeX + hhmmWidth + gap * 2;
        var zoneH = digitH / 3;

        dc.setColor(COLOR_WARM, Graphics.COLOR_TRANSPARENT);

        // Zone 1: seconds (7-segment)
        var z1Top = timeY;
        var z1Mid = z1Top + zoneH / 2;
        var sH = (zoneH - 2);
        if (sH < 6) { sH = 6; }
        var sW = (sH / 2).toNumber();
        var sT = (sH * 0.14).toNumber();
        if (sT < 1) { sT = 1; }
        var sG = (sW * 0.25).toNumber();
        if (sG < 1) { sG = 1; }
        var sY = z1Mid - sH / 2;

        if (_showSeconds && seconds != null) {
            SegmentRenderer.drawDigit(dc, seconds / 10, rightColX, sY, sW, sH, sT, COLOR_WARM);
            SegmentRenderer.drawDigit(dc, seconds % 10, rightColX + sW + sG, sY, sW, sH, sT, COLOR_WARM);
        }

        var moonSize = zoneH - 2;
        if (moonSize < 8) { moonSize = 8; }
        var moonR = moonSize / 2;
        var moonCx = rightColX + 2 * sW + sG + 4 + moonR;
        _drawMoonIcon(dc, moonCx, z1Mid, moonR, _getMoonPhase(), COLOR_WARM);

        // Zone 2: date (right-aligned)
        var z2Mid = timeY + zoneH + zoneH / 2;
        var dateFont = _pickFontForHeight(dc, zoneH);
        var dateFontH = dc.getFontHeight(dateFont);
        var monthNames = ["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"];
        var monthIdx = (now.month != null ? (now.month as Number) : 1) - 1;
        if (monthIdx < 0) { monthIdx = 0; }
        if (monthIdx > 11) { monthIdx = 11; }
        var dayN = now.day != null ? (now.day as Number) : 1;
        var dateStr = _pad2(dayN) + monthNames[monthIdx];

        var dowFont = _pickFontForHeight(dc, zoneH);
        var dowFontH = dc.getFontHeight(dowFont);
        var dowNames = ["SUN","MON","TUE","WED","THU","FRI","SAT"];
        var dowIdx = (now.day_of_week != null ? (now.day_of_week as Number) - 1 : 0);
        if (dowIdx < 0) { dowIdx = 0; }
        if (dowIdx > 6) { dowIdx = 6; }
        var dowStr = dowNames[dowIdx];

        var iconSize = zoneH - 2;
        if (iconSize < 8) { iconSize = 8; }

        // Right boundary used by zones 2 and 3.
        var dateW = dc.getTextWidthInPixels(dateStr, dateFont);
        var dowW = dc.getTextWidthInPixels(dowStr, dowFont);
        var z3W = dowW + 4 + iconSize;
        var maxW = dateW > z3W ? dateW : z3W;
        var rightEdge = rightColX + maxW;

        dc.drawText(rightEdge, z2Mid - dateFontH / 2, dateFont, dateStr,
                    Graphics.TEXT_JUSTIFY_RIGHT);

        // Zone 3: day of week (right-aligned) + weather icon at the far right
        var z3Mid = timeY + 2 * zoneH + zoneH / 2;
        var iconCx = rightEdge - iconSize / 2;
        var iconType = WeatherIcons.conditionToIcon(_data.getWeatherCondition());
        WeatherIcons.drawIcon(dc, iconType, iconCx, z3Mid, iconSize, COLOR_WARM);
        dc.drawText(iconCx - iconSize / 2 - 4, z3Mid - dowFontH / 2, dowFont, dowStr,
                    Graphics.TEXT_JUSTIFY_RIGHT);

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
        var sol = _formatSolar();
        if (sol != null) {
            bottomItems.add(sol);
        }

        _drawCurvedText(dc, w, h, topItems, 90.0,
            Graphics.RADIAL_TEXT_DIRECTION_CLOCKWISE);
        _drawCurvedText(dc, w, h, bottomItems, 270.0,
            Graphics.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE);
    }

    private function _drawCurvedText(dc as Dc, w as Number, h as Number,
                                     items as Array<String>,
                                     angleDeg as Float,
                                     direction as Number) as Void {
        if (items.size() == 0 || _curvedFont == null) { return; }
        var cx = w / 2;
        var cy = h / 2;
        var fontH = dc.getFontHeight(_curvedFont);
        var r = (w / 2) - fontH / 2 - 4;

        var text = items[0];
        for (var i = 1; i < items.size(); i++) {
            text += "   " + items[i];
        }

        dc.setColor(COLOR_WARM, Graphics.COLOR_TRANSPARENT);
        dc.drawRadialText(cx, cy, _curvedFont, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            angleDeg, r, direction);
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
        return cur != null ? "W " + cur.toNumber().toString() + "°" : "W --°";
    }

    private function _formatSensorTemp() as String {
        var t = _data.getSensorTemp();
        if (t == null) { return "T --°"; }
        return "T " + t.toNumber().toString() + "°";
    }

    private function _formatBattery() as String {
        var pct = System.getSystemStats().battery;
        return "BAT " + pct.format("%d") + "%";
    }

    private function _formatSolar() as String? {
        var s = _data.getSolarIntensity();
        if (s == null) { return null; }
        return "SOL " + s.toString() + "K";
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

    private function _getMoonPhase() as Float {
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var year = info.year != null ? info.year as Number : 2000;
        var month = info.month != null ? info.month as Number : 1;
        var day = info.day != null ? info.day as Number : 1;

        var y = year;
        var m = month;
        if (m < 3) {
            y -= 1;
            m += 12;
        }
        m += 1;
        var c = 365.25 * y;
        var e = 30.6 * m;
        var jd = c + e + day - 694039.09;
        jd /= 29.5305882;
        var b = jd.toNumber();
        var frac = jd - b;
        if (frac < 0) { frac += 1.0; }
        return frac.toFloat();
    }

    private function _drawMoonIcon(dc as Dc, cx as Number, cy as Number,
                                   r as Number, phase as Float, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, r);

        if (phase < 0.04 || phase > 0.96) { return; }
        if (phase > 0.46 && phase < 0.54) {
            dc.fillCircle(cx, cy, r);
            return;
        }

        var pi = Math.PI;
        var a = r * Math.cos(phase * 2.0 * pi);
        var n = 12;
        var pts = [] as Array< Array<Number> >;

        if (phase < 0.5) {
            // Waxing — right limb + terminator from bottom back to top
            for (var i = 0; i <= n; i++) {
                var t = i.toFloat() / n.toFloat();
                var ang = -pi / 2.0 + pi * t;
                pts.add([
                    cx + (r * Math.cos(ang)).toNumber(),
                    cy + (r * Math.sin(ang)).toNumber()
                ] as Array<Number>);
            }
            for (var i = 0; i <= n; i++) {
                var t = i.toFloat() / n.toFloat();
                var ang = pi / 2.0 - pi * t;
                pts.add([
                    cx + (a * Math.cos(ang)).toNumber(),
                    cy + (r * Math.sin(ang)).toNumber()
                ] as Array<Number>);
            }
        } else {
            // Waning — left limb + terminator from top back to bottom
            for (var i = 0; i <= n; i++) {
                var t = i.toFloat() / n.toFloat();
                var ang = pi / 2.0 + pi * t;
                pts.add([
                    cx + (r * Math.cos(ang)).toNumber(),
                    cy + (r * Math.sin(ang)).toNumber()
                ] as Array<Number>);
            }
            for (var i = 0; i <= n; i++) {
                var t = i.toFloat() / n.toFloat();
                var ang = 3.0 * pi / 2.0 - pi * t;
                pts.add([
                    cx + (a * Math.cos(ang)).toNumber(),
                    cy + (r * Math.sin(ang)).toNumber()
                ] as Array<Number>);
            }
        }

        dc.fillPolygon(pts);
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
