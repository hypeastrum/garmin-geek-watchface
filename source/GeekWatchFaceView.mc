import Toybox.Complications;
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
    private var _hitRegions as Array = [] as Array;

    function hitTest(x as Number, y as Number) as Number? {
        for (var i = 0; i < _hitRegions.size(); i++) {
            var r = _hitRegions[i] as Dictionary;
            var kind = r[:kind];
            if (kind == :rect) {
                var rx = r[:x] as Number;
                var ry = r[:y] as Number;
                var rw = r[:w] as Number;
                var rh = r[:h] as Number;
                if (x >= rx && x < rx + rw && y >= ry && y < ry + rh) {
                    return r[:type] as Number;
                }
            } else if (kind == :arc) {
                var cx = r[:cx] as Number;
                var cy = r[:cy] as Number;
                var dx = (x - cx).toFloat();
                var dy = (y - cy).toFloat();
                var dist = Math.sqrt(dx * dx + dy * dy);
                var rInner = r[:rInner] as Number;
                var rOuter = r[:rOuter] as Number;
                if (dist < rInner || dist > rOuter) { continue; }
                var ang = Math.atan2(-dy, dx) * 180.0 / Math.PI;
                if (ang < 0) { ang += 360.0; }
                var a0 = r[:angStart] as Float;
                var a1 = r[:angEnd] as Float;
                var hit = false;
                if (a0 <= a1) {
                    hit = (ang >= a0 && ang <= a1);
                } else {
                    hit = (ang >= a0 || ang <= a1);
                }
                if (hit) { return r[:type] as Number; }
            }
        }
        return null;
    }

    private function _addRectHit(x as Number, y as Number, w as Number, h as Number,
                                 compType as Number) as Void {
        _hitRegions.add({:kind => :rect, :x => x, :y => y, :w => w, :h => h, :type => compType});
    }

    private function _addArcHit(cx as Number, cy as Number,
                                rInner as Number, rOuter as Number,
                                angStart as Float, angEnd as Float,
                                compType as Number) as Void {
        var a0 = angStart;
        var a1 = angEnd;
        while (a0 < 0) { a0 += 360.0; } while (a0 >= 360) { a0 -= 360.0; }
        while (a1 < 0) { a1 += 360.0; } while (a1 >= 360) { a1 -= 360.0; }
        _hitRegions.add({:kind => :arc, :cx => cx, :cy => cy,
                         :rInner => rInner, :rOuter => rOuter,
                         :angStart => a0, :angEnd => a1, :type => compType});
    }

    function initialize() {
        WatchFace.initialize();
        _data = new DataProvider();
    }

    function onLayout(dc as Dc) as Void {
        if (Graphics has :getVectorFont) {
            var size = (dc.getHeight() * 0.072).toNumber();
            if (size < 12) { size = 12; }
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
        _hitRegions = [] as Array;

        var L = _computeLayout(dc);
        var w = L[:w] as Number;
        var h = L[:h] as Number;
        var timeX = L[:timeX] as Number;
        var timeY = L[:timeY] as Number;
        var digitH = L[:digitH] as Number;
        var digitW = L[:digitW] as Number;
        var thickness = L[:thickness] as Number;
        var gap = L[:gap] as Number;
        var rightColX = L[:rightColX] as Number;
        var rightEdge = L[:rightEdge] as Number;
        var zoneH = L[:zoneH] as Number;

        // --- Time ---
        var now = L[:now] as Gregorian.Info;
        var hours = now.hour != null ? now.hour as Number : 0;
        var minutes = now.min != null ? now.min as Number : 0;
        var seconds = (_showSeconds && now.sec != null) ? now.sec as Number : null;

        var settings = System.getDeviceSettings();
        if (!settings.is24Hour && hours > 12) {
            hours -= 12;
        } else if (!settings.is24Hour && hours == 0) {
            hours = 12;
        }

        SegmentRenderer.drawTime(dc, hours, minutes, null,
                                 timeX, timeY,
                                 digitW, digitH, thickness, gap,
                                 COLOR_WARM,
                                 null, null, null);

        dc.setColor(COLOR_WARM, Graphics.COLOR_TRANSPARENT);

        // Zone 1: seconds (7-segment) + moon icon
        var z1Mid = timeY + zoneH / 2;
        var sH = L[:sH] as Number;
        var sW = L[:sW] as Number;
        var sG = L[:sG] as Number;
        var sT = (sH * 0.14).toNumber();
        if (sT < 1) { sT = 1; }
        var sY = z1Mid - sH / 2;

        if (_showSeconds && seconds != null) {
            SegmentRenderer.drawDigit(dc, seconds / 10, rightColX, sY, sW, sH, sT, COLOR_WARM);
            SegmentRenderer.drawDigit(dc, seconds % 10, rightColX + sW + sG, sY, sW, sH, sT, COLOR_WARM);
        }

        var moonSize = L[:moonSize] as Number;
        var moonR = moonSize / 2;
        var moonCx = rightColX + 2 * sW + sG + 4 + moonR;
        _drawMoonIcon(dc, moonCx, z1Mid, moonR, _getMoonPhase(), COLOR_WARM);
        _addRectHit(moonCx - moonR, z1Mid - moonR, 2 * moonR, 2 * moonR,
                    Complications.COMPLICATION_TYPE_SUNRISE);

        // Zone 2: date (right-aligned)
        var z2Mid = timeY + zoneH + zoneH / 2;
        var dateFont = L[:dateFont] as FontType;
        var dateFontH = dc.getFontHeight(dateFont);
        var dateStr = L[:dateStr] as String;
        var dateW = L[:dateW] as Number;

        var dowFont = L[:dowFont] as FontType;
        var dowFontH = dc.getFontHeight(dowFont);
        var dowStr = L[:dowStr] as String;
        var dowW = L[:dowW] as Number;
        var iconSize = L[:iconSize] as Number;

        dc.drawText(rightEdge, z2Mid - dateFontH / 2, dateFont, dateStr,
                    Graphics.TEXT_JUSTIFY_RIGHT);
        _addRectHit(rightEdge - dateW, z2Mid - dateFontH / 2, dateW, dateFontH,
                    Complications.COMPLICATION_TYPE_CALENDAR_EVENTS);

        // Zone 3: day of week (right-aligned) + weather icon at the far right
        var z3Mid = timeY + 2 * zoneH + zoneH / 2;
        var iconCx = rightEdge - iconSize / 2;
        var iconTypeId = WeatherIcons.conditionToIcon(_data.getWeatherCondition());
        WeatherIcons.drawIcon(dc, iconTypeId, iconCx, z3Mid, iconSize, COLOR_WARM);
        _addRectHit(iconCx - iconSize / 2, z3Mid - iconSize / 2, iconSize, iconSize,
                    Complications.COMPLICATION_TYPE_CURRENT_WEATHER);
        var dowTextX = iconCx - iconSize / 2 - 4;
        dc.drawText(dowTextX, z3Mid - dowFontH / 2, dowFont, dowStr,
                    Graphics.TEXT_JUSTIFY_RIGHT);
        _addRectHit(dowTextX - dowW, z3Mid - dowFontH / 2, dowW, dowFontH,
                    Complications.COMPLICATION_TYPE_CALENDAR_EVENTS);

        // --- Arc items ---
        var topItems = [
            _formatSunRange(),
            _formatAlt(),
            _formatWeather(),
            _formatSensorTemp(),
            _formatBattery()
        ] as Array<String>;
        var topTypes = [
            Complications.COMPLICATION_TYPE_SUNRISE,
            Complications.COMPLICATION_TYPE_ALTITUDE,
            Complications.COMPLICATION_TYPE_CURRENT_WEATHER,
            Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE,
            Complications.COMPLICATION_TYPE_BATTERY
        ] as Array<Number>;

        var bottomItems = [
            _formatHr(),
            _formatStress(),
            _formatBodyBattery(),
            _formatSteps()
        ] as Array<String>;
        var bottomTypes = [
            Complications.COMPLICATION_TYPE_HEART_RATE,
            Complications.COMPLICATION_TYPE_STRESS,
            Complications.COMPLICATION_TYPE_BODY_BATTERY,
            Complications.COMPLICATION_TYPE_STEPS
        ] as Array<Number>;
        var sol = _formatSolar();
        if (sol != null) {
            bottomItems.add(sol);
            bottomTypes.add(Complications.COMPLICATION_TYPE_SOLAR_INPUT);
        }

        _drawCurvedText(dc, w, h, topItems, topTypes, 90.0,
            Graphics.RADIAL_TEXT_DIRECTION_CLOCKWISE);
        _drawCurvedText(dc, w, h, bottomItems, bottomTypes, 270.0,
            Graphics.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE);
    }

    // Called by the system roughly every second when the watch is active.
    // Redraws only the time-sensitive regions: seconds, top arc (alt, sensor
    // temp, battery), bottom arc (HR, stress, body battery, steps). Time
    // digits, date, weekday, moon and weather icon are left alone — they
    // refresh at the next full onUpdate.
    function onPartialUpdate(dc as Dc) as Void {
        var L = _computeLayout(dc);
        var w = L[:w] as Number;
        var h = L[:h] as Number;
        var timeY = L[:timeY] as Number;
        var digitH = L[:digitH] as Number;
        var rightColX = L[:rightColX] as Number;
        var zoneH = L[:zoneH] as Number;
        var z1Mid = timeY + zoneH / 2;

        var now = L[:now] as Gregorian.Info;
        var seconds = (_showSeconds && now.sec != null) ? now.sec as Number : null;

        // --- Seconds (zone 1, right column) ---
        if (_showSeconds && seconds != null) {
            var sH = L[:sH] as Number;
            var sW = L[:sW] as Number;
            var sG = L[:sG] as Number;
            var sT = (sH * 0.14).toNumber();
            if (sT < 1) { sT = 1; }
            var sY = z1Mid - sH / 2;
            dc.setClip(rightColX, sY, 2 * sW + sG + 2, sH);
            dc.setColor(COLOR_WARM, Graphics.COLOR_BLACK);
            dc.clear();
            SegmentRenderer.drawDigit(dc, seconds / 10, rightColX, sY, sW, sH, sT, COLOR_WARM);
            SegmentRenderer.drawDigit(dc, seconds % 10, rightColX + sW + sG, sY, sW, sH, sT, COLOR_WARM);
            dc.clearClip();
        }

        // --- Top arc ---
        var topItems = [
            _formatSunRange(),
            _formatAlt(),
            _formatWeather(),
            _formatSensorTemp(),
            _formatBattery()
        ] as Array<String>;
        dc.setClip(0, 0, w, timeY);
        dc.setColor(COLOR_WARM, Graphics.COLOR_BLACK);
        dc.clear();
        _drawCurvedText(dc, w, h, topItems, null, 90.0,
            Graphics.RADIAL_TEXT_DIRECTION_CLOCKWISE);
        dc.clearClip();

        // --- Bottom arc ---
        var bottomItems = [
            _formatHr(),
            _formatStress(),
            _formatBodyBattery(),
            _formatSteps()
        ] as Array<String>;
        var sol = _formatSolar();
        if (sol != null) { bottomItems.add(sol); }
        dc.setClip(0, timeY + digitH, w, h - timeY - digitH);
        dc.setColor(COLOR_WARM, Graphics.COLOR_BLACK);
        dc.clear();
        _drawCurvedText(dc, w, h, bottomItems, null, 270.0,
            Graphics.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE);
        dc.clearClip();
    }

    private function _drawCurvedText(dc as Dc, w as Number, h as Number,
                                     items as Array<String>,
                                     types as Array<Number>?,
                                     angleDeg as Float,
                                     direction as Number) as Void {
        if (items.size() == 0 || _curvedFont == null) { return; }
        var cx = w / 2;
        var cy = h / 2;
        var fontH = dc.getFontHeight(_curvedFont);
        var r = (w / 2) - fontH / 2 - 4;

        var sep = "   ";
        var sepW = dc.getTextWidthInPixels(sep, _curvedFont).toFloat();
        var itemWidths = new [items.size()];
        var totalW = 0.0;
        for (var i = 0; i < items.size(); i++) {
            var iw = dc.getTextWidthInPixels(items[i], _curvedFont).toFloat();
            itemWidths[i] = iw;
            totalW += iw;
            if (i > 0) { totalW += sepW; }
        }

        var text = items[0];
        for (var i = 1; i < items.size(); i++) {
            text += sep + items[i];
        }

        dc.setColor(COLOR_WARM, Graphics.COLOR_TRANSPARENT);
        dc.drawRadialText(cx, cy, _curvedFont, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            angleDeg, r, direction);

        if (types == null) { return; }

        // CW = decreasing angle from anchor as text advances; CCW = increasing.
        var sign = (direction == Graphics.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE) ? 1.0 : -1.0;
        var rad = r.toFloat();
        var totalSpanDeg = totalW * 180.0 / (Math.PI * rad);
        var startAng = angleDeg - sign * totalSpanDeg / 2.0;
        var rInner = (r - fontH / 2 - 4).toNumber();
        var rOuter = (r + fontH / 2 + 4).toNumber();
        if (rInner < 0) { rInner = 0; }

        var cumW = 0.0;
        for (var i = 0; i < items.size(); i++) {
            var iw = itemWidths[i] as Float;
            if (i < types.size() && types[i] != null) {
                var midW = cumW + iw / 2.0;
                var midAng = startAng + sign * midW * 180.0 / (Math.PI * rad);
                var itemSpan = iw * 180.0 / (Math.PI * rad);
                _addArcHit(cx, cy, rInner, rOuter,
                           (midAng - itemSpan / 2.0).toFloat(),
                           (midAng + itemSpan / 2.0).toFloat(),
                           types[i] as Number);
            }
            cumW += iw + sepW;
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
        return cur != null ? "W " + cur.toNumber().toString() + "°" : "W --°";
    }

    private function _formatSensorTemp() as String {
        var t = _data.getSensorTemp();
        if (t == null) { return "T --°"; }
        return "T " + t.toNumber().toString() + "°";
    }

    private function _formatBattery() as String {
        var stats = System.getSystemStats();
        var s = "BAT " + stats.battery.format("%d") + "%";
        if (stats has :batteryInDays && stats.batteryInDays != null) {
            s += "/" + stats.batteryInDays.format("%d") + "d";
        }
        return s;
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

    // Computes time-block + right-column geometry, including the right column
    // width (based on date / weekday / seconds+moon widths). The whole
    // [time + gap + right-column] group is centered horizontally on screen.
    private function _computeLayout(dc as Dc) as Dictionary {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var leftAreaW = (w * 0.6).toNumber();

        var widthFactor = 3.85;
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
        var zoneH = digitH / 3;

        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var monthNames = ["JAN","FEB","MAR","APR","MAY","JUN",
                          "JUL","AUG","SEP","OCT","NOV","DEC"];
        var monthIdx = (now.month != null ? (now.month as Number) : 1) - 1;
        if (monthIdx < 0) { monthIdx = 0; }
        if (monthIdx > 11) { monthIdx = 11; }
        var dayN = now.day != null ? (now.day as Number) : 1;
        var dateStr = _pad2(dayN) + monthNames[monthIdx];

        var dowNames = ["SUN","MON","TUE","WED","THU","FRI","SAT"];
        var dowIdx = (now.day_of_week != null ? (now.day_of_week as Number) - 1 : 0);
        if (dowIdx < 0) { dowIdx = 0; }
        if (dowIdx > 6) { dowIdx = 6; }
        var dowStr = dowNames[dowIdx];

        var dateFont = _pickFontForHeight(dc, zoneH);
        var dowFont = _pickFontForHeight(dc, zoneH);
        var dateW = dc.getTextWidthInPixels(dateStr, dateFont);
        var dowW = dc.getTextWidthInPixels(dowStr, dowFont);

        var sH = (zoneH - 2);
        if (sH < 6) { sH = 6; }
        var sW = (sH / 2).toNumber();
        var sG = (sW * 0.25).toNumber();
        if (sG < 1) { sG = 1; }
        var moonSize = zoneH - 2;
        if (moonSize < 8) { moonSize = 8; }
        var iconSize = zoneH - 2;
        if (iconSize < 8) { iconSize = 8; }

        var z1W = 2 * sW + sG + 4 + moonSize;
        var z3W = dowW + 4 + iconSize;
        var rightColW = z1W;
        if (dateW > rightColW) { rightColW = dateW; }
        if (z3W > rightColW) { rightColW = z3W; }

        var totalW = hhmmWidth + gap * 2 + rightColW;
        var timeX = (w - totalW) / 2;
        if (timeX < 4) { timeX = 4; }
        var timeY = (h - digitH) / 2;
        var rightColX = timeX + hhmmWidth + gap * 2;
        var rightEdge = rightColX + rightColW;

        return {
            :w => w, :h => h,
            :timeX => timeX, :timeY => timeY,
            :digitH => digitH, :digitW => digitW,
            :thickness => thickness, :gap => gap, :colonSize => colonSize,
            :hhmmWidth => hhmmWidth,
            :rightColX => rightColX, :rightEdge => rightEdge, :rightColW => rightColW,
            :zoneH => zoneH,
            :sH => sH, :sW => sW, :sG => sG,
            :moonSize => moonSize, :iconSize => iconSize,
            :dateStr => dateStr, :dowStr => dowStr,
            :dateFont => dateFont, :dowFont => dowFont,
            :dateW => dateW, :dowW => dowW,
            :now => now
        } as Dictionary;
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
