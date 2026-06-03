import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Weather;

// Programmatic weather icon drawing.
// Maps Weather.CONDITION_* enums to simple drawn icons.

module WeatherIcons {

    enum IconType {
        ICON_SUN,
        ICON_PARTLY_CLOUDY,
        ICON_CLOUDY,
        ICON_RAIN,
        ICON_HEAVY_RAIN,
        ICON_THUNDER,
        ICON_SNOW,
        ICON_SLEET,
        ICON_FOG,
        ICON_WIND,
        ICON_HAZE,
        ICON_UNKNOWN,
    }

    // Map a Weather.CONDITION_* value to an IconType.
    function conditionToIcon(condition as Number?) as IconType {
        if (condition == null) {
            return ICON_UNKNOWN;
        }

        switch (condition) {
            case Weather.CONDITION_CLEAR:
            case Weather.CONDITION_FAIR:
                return ICON_SUN;

            case Weather.CONDITION_PARTLY_CLOUDY:
            case Weather.CONDITION_MOSTLY_CLEAR:
            case Weather.CONDITION_THIN_CLOUDS:
            case Weather.CONDITION_PARTLY_CLEAR:
                return ICON_PARTLY_CLOUDY;

            case Weather.CONDITION_MOSTLY_CLOUDY:
            case Weather.CONDITION_CLOUDY:
                return ICON_CLOUDY;

            case Weather.CONDITION_LIGHT_RAIN:
            case Weather.CONDITION_RAIN:
            case Weather.CONDITION_SHOWERS:
            case Weather.CONDITION_CHANCE_OF_SHOWERS:
            case Weather.CONDITION_SCATTERED_SHOWERS:
            case Weather.CONDITION_LIGHT_SHOWERS:
            case Weather.CONDITION_DRIZZLE:
            case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN:
            case Weather.CONDITION_UNKNOWN_PRECIPITATION:
                return ICON_RAIN;

            case Weather.CONDITION_HEAVY_RAIN:
            case Weather.CONDITION_HEAVY_SHOWERS:
                return ICON_HEAVY_RAIN;

            case Weather.CONDITION_THUNDERSTORMS:
            case Weather.CONDITION_SCATTERED_THUNDERSTORMS:
            case Weather.CONDITION_CHANCE_OF_THUNDERSTORMS:
            case Weather.CONDITION_TROPICAL_STORM:
            case Weather.CONDITION_HURRICANE:
            case Weather.CONDITION_TORNADO:
                return ICON_THUNDER;

            case Weather.CONDITION_SNOW:
            case Weather.CONDITION_LIGHT_SNOW:
            case Weather.CONDITION_HEAVY_SNOW:
            case Weather.CONDITION_CHANCE_OF_SNOW:
            case Weather.CONDITION_FLURRIES:
            case Weather.CONDITION_ICE:
            case Weather.CONDITION_HAIL:
                return ICON_SNOW;

            case Weather.CONDITION_RAIN_SNOW:
            case Weather.CONDITION_WINTRY_MIX:
            case Weather.CONDITION_FREEZING_RAIN:
            case Weather.CONDITION_SLEET:
            case Weather.CONDITION_ICE_SNOW:
                return ICON_SLEET;

            case Weather.CONDITION_FOG:
            case Weather.CONDITION_MIST:
            case Weather.CONDITION_VOLCANIC_ASH:
            case Weather.CONDITION_SMOKE:
                return ICON_FOG;

            case Weather.CONDITION_WINDY:
            case Weather.CONDITION_SQUALL:
            case Weather.CONDITION_SANDSTORM:
            case Weather.CONDITION_DUST:
                return ICON_WIND;

            case Weather.CONDITION_HAZY:
                return ICON_HAZE;

            default:
                return ICON_UNKNOWN;
        }
    }

    // Draw the weather icon at (cx, cy) center, fitting in size x size box.
    function drawIcon(dc as Dc, icon as IconType, cx as Number, cy as Number,
                      size as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);

        switch (icon) {
            case ICON_SUN:
                _drawSun(dc, cx, cy, size);
                break;
            case ICON_PARTLY_CLOUDY:
                _drawSun(dc, cx - size / 5, cy - size / 5, size * 2 / 3);
                _drawCloud(dc, cx + size / 8, cy + size / 8, size * 2 / 3, color);
                break;
            case ICON_CLOUDY:
                _drawCloud(dc, cx, cy, size, color);
                break;
            case ICON_RAIN:
                _drawCloud(dc, cx, cy - size / 6, size * 3 / 4, color);
                _drawRainDrops(dc, cx, cy + size / 4, size, 3, color);
                break;
            case ICON_HEAVY_RAIN:
                _drawCloud(dc, cx, cy - size / 6, size * 3 / 4, color);
                _drawRainDrops(dc, cx, cy + size / 4, size, 5, color);
                break;
            case ICON_THUNDER:
                _drawCloud(dc, cx, cy - size / 5, size * 3 / 4, color);
                _drawBolt(dc, cx, cy + size / 6, size / 2, color);
                break;
            case ICON_SNOW:
                _drawCloud(dc, cx, cy - size / 6, size * 3 / 4, color);
                _drawSnowDots(dc, cx, cy + size / 4, size, color);
                break;
            case ICON_SLEET:
                _drawCloud(dc, cx, cy - size / 6, size * 3 / 4, color);
                _drawRainDrops(dc, cx - size / 6, cy + size / 4, size / 2, 2, color);
                _drawSnowDot(dc, cx + size / 4, cy + size / 3, size / 10, color);
                break;
            case ICON_FOG:
                _drawFog(dc, cx, cy, size, color);
                break;
            case ICON_WIND:
                _drawWind(dc, cx, cy, size, color);
                break;
            case ICON_HAZE:
                _drawFog(dc, cx, cy, size, color);
                break;
            case ICON_UNKNOWN:
                // Draw a question mark-ish shape: just a small dot
                dc.fillCircle(cx, cy, size / 6);
                break;
        }
    }

    // --- Private drawing helpers ---

    function _drawSun(dc as Dc, cx as Number, cy as Number, size as Number) as Void {
        var r = size / 3;
        dc.fillCircle(cx, cy, r);
        // Rays: 8 short lines
        var rayLen = size / 2;
        var rayInner = r + 2;
        for (var i = 0; i < 8; i++) {
            var angle = i * 0.7854; // pi/4
            var cos = _cos(angle);
            var sin = _sin(angle);
            var x1 = cx + (rayInner * cos).toNumber();
            var y1 = cy + (rayInner * sin).toNumber();
            var x2 = cx + (rayLen * cos).toNumber();
            var y2 = cy + (rayLen * sin).toNumber();
            dc.drawLine(x1, y1, x2, y2);
        }
    }

    function _drawCloud(dc as Dc, cx as Number, cy as Number, size as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var r = size / 4;
        // Three overlapping circles
        dc.fillCircle(cx - r, cy, r);
        dc.fillCircle(cx, cy - r / 2, r);
        dc.fillCircle(cx + r, cy, r);
        // Flat bottom
        dc.fillRectangle(cx - r - r / 2, cy, r * 3, r / 2);
    }

    function _drawRainDrops(dc as Dc, cx as Number, y as Number, size as Number,
                                    count as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var spacing = size / (count + 1);
        var startX = cx - size / 3;
        for (var i = 0; i < count; i++) {
            var dx = startX + spacing * (i + 1);
            dc.drawLine(dx.toNumber(), y, (dx - 1).toNumber(), y + size / 5);
        }
    }

    function _drawBolt(dc as Dc, cx as Number, cy as Number, size as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [cx - size / 6, cy - size / 2] as Array<Number>,
            [cx + size / 4, cy - size / 2] as Array<Number>,
            [cx, cy] as Array<Number>,
            [cx + size / 3, cy] as Array<Number>,
            [cx - size / 6, cy + size / 2] as Array<Number>,
            [cx, cy - size / 6] as Array<Number>,
            [cx - size / 3, cy - size / 6] as Array<Number>,
        ] as Array< Array<Number> >);
    }

    function _drawSnowDots(dc as Dc, cx as Number, y as Number, size as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var dotR = size / 12;
        if (dotR < 1) { dotR = 1; }
        dc.fillCircle(cx - size / 4, y, dotR);
        dc.fillCircle(cx, y + size / 8, dotR);
        dc.fillCircle(cx + size / 4, y, dotR);
    }

    function _drawSnowDot(dc as Dc, x as Number, y as Number, r as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        if (r < 1) { r = 1; }
        dc.fillCircle(x, y, r);
    }

    function _drawFog(dc as Dc, cx as Number, cy as Number, size as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        var halfW = size / 3;
        for (var i = -1; i <= 1; i++) {
            var ly = cy + i * (size / 5);
            dc.drawLine(cx - halfW, ly, cx + halfW, ly);
        }
        dc.setPenWidth(1);
    }

    function _drawWind(dc as Dc, cx as Number, cy as Number, size as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        var left = cx - size / 3;
        var right = cx + size / 3;
        // Three horizontal lines with curved ends (simplified as angled tips)
        for (var i = -1; i <= 1; i++) {
            var ly = cy + i * (size / 5);
            dc.drawLine(left, ly, right, ly);
            dc.drawLine(right, ly, right + size / 8, ly - size / 8);
        }
        dc.setPenWidth(1);
    }

    // Simple sin/cos approximation using lookup (avoids Math import issues).
    function _cos(angle as Float) as Float {
        return _sin(angle + 1.5708);
    }

    function _sin(angle as Float) as Float {
        // Normalize to [0, 2*PI)
        var twoPi = 6.2832;
        var a = angle;
        while (a < 0.0) { a += twoPi; }
        while (a >= twoPi) { a -= twoPi; }

        // Bhaskara I approximation
        var pi = 3.14159;
        if (a > pi) {
            return -_sinHalf(a - pi);
        }
        return _sinHalf(a);
    }

    function _sinHalf(a as Float) as Float {
        // Approximation for a in [0, PI]
        var pi = 3.14159;
        var num = 16.0 * a * (pi - a);
        var den = 5.0 * pi * pi - 4.0 * a * (pi - a);
        return num / den;
    }
}
