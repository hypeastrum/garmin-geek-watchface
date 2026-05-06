import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class GeekWatchFaceView extends WatchUi.WatchFace {

    // Colors
    private const COLOR_BRIGHT = 0x00FF00;
    private const COLOR_DIM    = 0x007700;
    private const COLOR_AMBER  = 0xFF8800;

    private var _data as DataProvider;
    private var _showSeconds as Boolean = true;
    private var _isAmoled as Boolean = false;

    function initialize() {
        WatchFace.initialize();
        _data = new DataProvider();
    }

    function onLayout(dc as Dc) as Void {
        // Detect AMOLED displays (typically 416px+)
        _isAmoled = dc.getWidth() >= 390;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(COLOR_BRIGHT, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();

        // Scale factors based on display size
        var scale = w.toFloat() / 260.0; // Normalize to 260px MIP base

        var marginLeft = (8 * scale).toNumber();
        var lineH = (18 * scale).toNumber();

        // --- 7-Segment Time ---
        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var hours = now.hour != null ? now.hour as Number : 0;
        var minutes = now.min != null ? now.min as Number : 0;
        var seconds = (_showSeconds && now.sec != null) ? now.sec as Number : null;

        // 12h/24h
        var settings = System.getDeviceSettings();
        if (!settings.is24Hour && hours > 12) {
            hours -= 12;
        } else if (!settings.is24Hour && hours == 0) {
            hours = 12;
        }

        // Digit sizing: ~35% of height for the time block
        var digitH = (h * 0.20).toNumber();
        var digitW = (digitH * 0.50).toNumber();
        var thickness = (digitH * 0.12).toNumber();
        if (thickness < 2) { thickness = 2; }
        var gap = (digitW * 0.25).toNumber();

        var secDigitW = (digitW * 0.60).toNumber();
        var secDigitH = (digitH * 0.65).toNumber();
        var secThickness = (thickness * 0.65).toNumber();
        if (secThickness < 1) { secThickness = 1; }

        // Vertical layout: compute total height of all rows to center vertically
        var timeBlockH = digitH;
        var dataRowCount = 5; // HR+STR, STP, Weather, ALT+UV, Sun
        var totalH = timeBlockH + lineH + dataRowCount * lineH;

        // Check if solar is available for extra row
        var solarVal = _data.getSolarIntensity();
        if (solarVal != null) {
            totalH += lineH;
        }

        var startY = (h - totalH) / 2;
        var cy = startY;

        // Draw time
        SegmentRenderer.drawTime(dc, hours, minutes, seconds,
                                 marginLeft, cy,
                                 digitW, digitH, thickness, gap,
                                 COLOR_BRIGHT,
                                 secDigitW, secDigitH, secThickness);
        cy += timeBlockH + lineH;

        // --- Data Rows ---
        // Font for labels
        var font = Graphics.FONT_XTINY;
        var fontH = dc.getFontHeight(font);
        var rowY;

        // Row 1: HR + Stress
        rowY = cy + (lineH - fontH) / 2;
        var hr = _data.getHeartRate();
        _drawLabel(dc, "HR:", marginLeft, rowY, font);
        var hrX = marginLeft + dc.getTextWidthInPixels("HR:", font);
        if (hr != null) {
            dc.setColor(COLOR_BRIGHT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(hrX, rowY, font, hr.toString(), Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
            dc.drawText(hrX, rowY, font, "--", Graphics.TEXT_JUSTIFY_LEFT);
        }

        var stressX = marginLeft + (w * 0.40).toNumber();
        var stress = _data.getStress();
        _drawLabel(dc, "STR:", stressX, rowY, font);
        var strValX = stressX + dc.getTextWidthInPixels("STR:", font);
        if (stress != null) {
            var stressColor = stress > 50 ? COLOR_AMBER : COLOR_BRIGHT;
            dc.setColor(stressColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(strValX, rowY, font, stress.toString(), Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
            dc.drawText(strValX, rowY, font, "--", Graphics.TEXT_JUSTIFY_LEFT);
        }
        cy += lineH;

        // Row 2: Steps
        rowY = cy + (lineH - fontH) / 2;
        var steps = _data.getSteps();
        var stepGoal = _data.getStepGoal();
        _drawLabel(dc, "STP:", marginLeft, rowY, font);
        var stpValX = marginLeft + dc.getTextWidthInPixels("STP:", font);
        dc.setColor(COLOR_BRIGHT, Graphics.COLOR_TRANSPARENT);
        var stepsStr = (steps != null ? steps.toString() : "--") +
                       "/" +
                       (stepGoal != null ? stepGoal.toString() : "--");
        dc.drawText(stpValX, rowY, font, stepsStr, Graphics.TEXT_JUSTIFY_LEFT);
        cy += lineH;

        // Row 3: Weather icon + lo/cur/hi temps
        rowY = cy + (lineH - fontH) / 2;
        var condition = _data.getWeatherCondition();
        var iconType = WeatherIcons.conditionToIcon(condition);
        var iconSize = (lineH * 0.8).toNumber();
        var iconCx = marginLeft + iconSize / 2;
        var iconCy = cy + lineH / 2;
        WeatherIcons.drawIcon(dc, iconType, iconCx, iconCy, iconSize, COLOR_BRIGHT);

        var tempX = marginLeft + iconSize + (4 * scale).toNumber();
        var lo = _data.getLowTemp();
        var cur = _data.getCurrentTemp();
        var hi = _data.getHighTemp();
        var tempStr = (lo != null ? lo.toString() : "--") + "/" +
                      (cur != null ? cur.toString() : "--") + "/" +
                      (hi != null ? hi.toString() : "--") + "\u00B0";
        dc.setColor(COLOR_BRIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(tempX, rowY, font, tempStr, Graphics.TEXT_JUSTIFY_LEFT);
        cy += lineH;

        // Row 4: ALT + UV
        rowY = cy + (lineH - fontH) / 2;
        var alt = _data.getAltitude();
        _drawLabel(dc, "ALT:", marginLeft, rowY, font);
        var altValX = marginLeft + dc.getTextWidthInPixels("ALT:", font);
        if (alt != null) {
            dc.setColor(COLOR_BRIGHT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(altValX, rowY, font, alt.toString() + "m", Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
            dc.drawText(altValX, rowY, font, "--", Graphics.TEXT_JUSTIFY_LEFT);
        }

        var uvX = marginLeft + (w * 0.55).toNumber();
        var uv = _data.getUvIndex();
        _drawLabel(dc, "UV:", uvX, rowY, font);
        var uvValX = uvX + dc.getTextWidthInPixels("UV:", font);
        if (uv != null) {
            var uvColor = uv >= 6 ? COLOR_AMBER : COLOR_BRIGHT;
            dc.setColor(uvColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(uvValX, rowY, font, uv.toString(), Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
            dc.drawText(uvValX, rowY, font, "--", Graphics.TEXT_JUSTIFY_LEFT);
        }
        cy += lineH;

        // Row 5: Sunrise / Sunset
        rowY = cy + (lineH - fontH) / 2;
        var sunrise = _data.getSunrise();
        var sunset = _data.getSunset();

        dc.setColor(COLOR_BRIGHT, Graphics.COLOR_TRANSPARENT);
        var sunStr = "\u2600"; // ☀ sun symbol
        dc.drawText(marginLeft, rowY, font, sunStr, Graphics.TEXT_JUSTIFY_LEFT);
        var srX = marginLeft + dc.getTextWidthInPixels(sunStr, font);
        if (sunrise != null) {
            var srInfo = Gregorian.info(sunrise, Time.FORMAT_SHORT);
            var srH = srInfo.hour != null ? srInfo.hour as Number : 0;
            var srM = srInfo.min != null ? srInfo.min as Number : 0;
            var srText = _pad2(srH) + ":" + _pad2(srM);
            dc.setColor(COLOR_BRIGHT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(srX, rowY, font, srText, Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
            dc.drawText(srX, rowY, font, "--:--", Graphics.TEXT_JUSTIFY_LEFT);
        }

        var moonX = marginLeft + (w * 0.42).toNumber();
        var moonStr = "\u263E"; // ☾ moon symbol
        dc.setColor(COLOR_BRIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(moonX, rowY, font, moonStr, Graphics.TEXT_JUSTIFY_LEFT);
        var ssX = moonX + dc.getTextWidthInPixels(moonStr, font);
        if (sunset != null) {
            var ssInfo = Gregorian.info(sunset, Time.FORMAT_SHORT);
            var ssH = ssInfo.hour != null ? ssInfo.hour as Number : 0;
            var ssM = ssInfo.min != null ? ssInfo.min as Number : 0;
            var ssText = _pad2(ssH) + ":" + _pad2(ssM);
            dc.setColor(COLOR_BRIGHT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(ssX, rowY, font, ssText, Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
            dc.drawText(ssX, rowY, font, "--:--", Graphics.TEXT_JUSTIFY_LEFT);
        }
        cy += lineH;

        // Row 6: Solar intensity (conditional)
        if (solarVal != null) {
            rowY = cy + (lineH - fontH) / 2;
            _drawLabel(dc, "SOL:", marginLeft, rowY, font);
            var solValX = marginLeft + dc.getTextWidthInPixels("SOL:", font);
            dc.setColor(COLOR_BRIGHT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(solValX, rowY, font, solarVal.toString() + "%", Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

    function onEnterSleep() as Void {
        _showSeconds = false;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        _showSeconds = true;
        WatchUi.requestUpdate();
    }

    // --- Helpers ---

    private function _drawLabel(dc as Dc, label as String, x as Number, y as Number, font as FontType) as Void {
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, label, Graphics.TEXT_JUSTIFY_LEFT);
    }

    private function _pad2(val as Number) as String {
        if (val < 10) {
            return "0" + val.toString();
        }
        return val.toString();
    }
}
