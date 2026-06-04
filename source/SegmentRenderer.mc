import Toybox.Graphics;
import Toybox.Lang;

// 7-segment digit renderer using filled polygons.
// Segments are trapezoids (horizontal) and parallelograms (vertical),
// with a small italic slant applied to every vertex.
// Segment layout:
//   _a_
//  |   |
//  f   b
//  |_g_|
//  |   |
//  e   c
//  |_d_|

module SegmentRenderer {

    const SLANT = 0.10;

    const DIGIT_SEGMENTS = [
        0x3F, // 0
        0x06, // 1
        0x5B, // 2
        0x4F, // 3
        0x66, // 4
        0x6D, // 5
        0x7D, // 6
        0x07, // 7
        0x7F, // 8
        0x6F, // 9
    ] as Array<Number>;

    function drawDigit(dc as Dc, digit as Number, x as Number, y as Number,
                       w as Number, h as Number, t as Number, color as Number) as Void {
        if (digit < 0 || digit > 9) {
            return;
        }
        var mask = DIGIT_SEGMENTS[digit];
        var hh = h / 2;
        // oi = outer corner inset: how far the outermost segment vertex sits
        //      from the digit edge. Smaller = segments reach closer to corners.
        // ii = inner inset = oi + t, keeps the 45° chamfer.
        // mp = padding between verticals and the middle segment.
        var oi = (t / 3).toNumber();
        if (oi < 2) { oi = 2; }
        var ii = oi + t;
        var mp = (t / 4).toNumber();
        if (mp < 1) { mp = 1; }
        var hexHalf = t / 2;

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);

        // a — top horizontal trapezoid
        if (mask & 0x01) {
            _fillSlantedPoly(dc, [
                [x + oi, y],
                [x + w - oi, y],
                [x + w - ii, y + t],
                [x + ii, y + t]
            ], y, h);
        }
        // b — top-right vertical parallelogram
        if (mask & 0x02) {
            _fillSlantedPoly(dc, [
                [x + w - t, y + ii],
                [x + w, y + oi],
                [x + w, y + hh - mp],
                [x + w - t, y + hh - mp - t]
            ], y, h);
        }
        // c — bottom-right vertical parallelogram
        if (mask & 0x04) {
            _fillSlantedPoly(dc, [
                [x + w - t, y + hh + mp + t],
                [x + w, y + hh + mp],
                [x + w, y + h - oi],
                [x + w - t, y + h - ii]
            ], y, h);
        }
        // d — bottom horizontal trapezoid
        if (mask & 0x08) {
            _fillSlantedPoly(dc, [
                [x + ii, y + h - t],
                [x + w - ii, y + h - t],
                [x + w - oi, y + h],
                [x + oi, y + h]
            ], y, h);
        }
        // e — bottom-left vertical parallelogram
        if (mask & 0x10) {
            _fillSlantedPoly(dc, [
                [x, y + hh + mp],
                [x + t, y + hh + mp + t],
                [x + t, y + h - ii],
                [x, y + h - oi]
            ], y, h);
        }
        // f — top-left vertical parallelogram
        if (mask & 0x20) {
            _fillSlantedPoly(dc, [
                [x, y + oi],
                [x + t, y + ii],
                [x + t, y + hh - mp - t],
                [x, y + hh - mp]
            ], y, h);
        }
        // g — middle horizontal hexagon (pointed tips left/right)
        if (mask & 0x40) {
            _fillSlantedPoly(dc, [
                [x + ii, y + hh - hexHalf],
                [x + w - ii, y + hh - hexHalf],
                [x + w - oi, y + hh],
                [x + w - ii, y + hh + hexHalf],
                [x + ii, y + hh + hexHalf],
                [x + oi, y + hh]
            ], y, h);
        }
    }

    function _fillSlantedPoly(dc as Dc, pts as Array,
                              yTop as Number, totalH as Number) as Void {
        var slanted = [] as Array< Array<Number> >;
        for (var i = 0; i < pts.size(); i++) {
            var p = pts[i] as Array<Number>;
            slanted.add(_slant(p[0], p[1], yTop, totalH));
        }
        dc.fillPolygon(slanted);
    }

    function _slant(px as Number, py as Number,
                    yTop as Number, totalH as Number) as Array<Number> {
        var shift = (SLANT * (yTop + totalH - py)).toNumber();
        return [px + shift, py] as Array<Number>;
    }

    // Colon: two slanted squares (parallelograms matching the digit slant).
    function drawColon(dc as Dc, x as Number, y as Number,
                       h as Number, size as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var topY = y + h / 3 - size / 2;
        var botY = y + 2 * h / 3 - size / 2;
        _slantedSquare(dc, x, topY, size, y, h);
        _slantedSquare(dc, x, botY, size, y, h);
    }

    function _slantedSquare(dc as Dc, sx as Number, sy as Number,
                            size as Number,
                            yTop as Number, totalH as Number) as Void {
        _fillSlantedPoly(dc, [
            [sx, sy],
            [sx + size, sy],
            [sx + size, sy + size],
            [sx, sy + size]
        ], yTop, totalH);
    }

    // Draw a full time string HH:MM or HH:MM:SS. Returns total width drawn.
    function drawTime(dc as Dc, hours as Number, minutes as Number, seconds as Number?,
                      x as Number, y as Number, digitW as Number, digitH as Number,
                      thickness as Number, gap as Number, color as Number,
                      secDigitW as Number?, secDigitH as Number?, secThickness as Number?) as Number {
        var cx = x;

        var h1 = hours / 10;
        var h2 = hours % 10;
        drawDigit(dc, h1, cx, y, digitW, digitH, thickness, color);
        cx += digitW + gap;
        drawDigit(dc, h2, cx, y, digitW, digitH, thickness, color);
        cx += digitW + gap;

        var colonSize = thickness + 1;
        drawColon(dc, cx, y, digitH, colonSize, color);
        cx += colonSize + gap;

        var m1 = minutes / 10;
        var m2 = minutes % 10;
        drawDigit(dc, m1, cx, y, digitW, digitH, thickness, color);
        cx += digitW + gap;
        drawDigit(dc, m2, cx, y, digitW, digitH, thickness, color);
        cx += digitW;

        if (seconds != null) {
            var sw = secDigitW != null ? secDigitW : digitW * 2 / 3;
            var sh = secDigitH != null ? secDigitH : digitH * 2 / 3;
            var st = secThickness != null ? secThickness : thickness * 2 / 3;
            if (st < 1) { st = 1; }
            var secY = y + digitH - sh;

            cx += gap;
            var sColonSize = st + 1;
            drawColon(dc, cx, secY, sh, sColonSize, color);
            cx += sColonSize + gap;

            var s1 = seconds / 10;
            var s2 = seconds % 10;
            drawDigit(dc, s1, cx, secY, sw, sh, st, color);
            cx += sw + gap;
            drawDigit(dc, s2, cx, secY, sw, sh, st, color);
            cx += sw;
        }

        return cx - x;
    }
}
