import Toybox.Graphics;
import Toybox.Lang;

// 7-segment digit renderer using filled polygons.
// Segment layout:
//   _a_
//  |   |
//  f   b
//  |_g_|
//  |   |
//  e   c
//  |_d_|

module SegmentRenderer {

    // Segment bitmasks: a=0x01 b=0x02 c=0x04 d=0x08 e=0x10 f=0x20 g=0x40
    const DIGIT_SEGMENTS = [
        0x3F, // 0: a b c d e f
        0x06, // 1: b c
        0x5B, // 2: a b d e g
        0x4F, // 3: a b c d g
        0x66, // 4: b c f g
        0x6D, // 5: a c d f g
        0x7D, // 6: a c d e f g
        0x07, // 7: a b c
        0x7F, // 8: a b c d e f g
        0x6F, // 9: a b c d f g
    ] as Array<Number>;

    // Draw a single 7-segment digit.
    // x, y = top-left corner of the digit bounding box.
    // w = width, h = height of the digit.
    // t = segment thickness.
    function drawDigit(dc as Dc, digit as Number, x as Number, y as Number,
                       w as Number, h as Number, t as Number, color as Number) as Void {
        if (digit < 0 || digit > 9) {
            return;
        }
        var mask = DIGIT_SEGMENTS[digit];
        var hh = h / 2; // half height

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);

        // Segment a — top horizontal
        if (mask & 0x01) {
            dc.fillPolygon([
                [x + t, y] as Array<Number>,
                [x + w - t, y] as Array<Number>,
                [x + w - t * 2, y + t] as Array<Number>,
                [x + t * 2, y + t] as Array<Number>,
            ] as Array< Array<Number> >);
        }

        // Segment b — top-right vertical
        if (mask & 0x02) {
            dc.fillPolygon([
                [x + w, y + t] as Array<Number>,
                [x + w, y + hh - 1] as Array<Number>,
                [x + w - t, y + hh - t] as Array<Number>,
                [x + w - t, y + t * 2] as Array<Number>,
            ] as Array< Array<Number> >);
        }

        // Segment c — bottom-right vertical
        if (mask & 0x04) {
            dc.fillPolygon([
                [x + w, y + hh + 1] as Array<Number>,
                [x + w, y + h - t] as Array<Number>,
                [x + w - t, y + h - t * 2] as Array<Number>,
                [x + w - t, y + hh + t] as Array<Number>,
            ] as Array< Array<Number> >);
        }

        // Segment d — bottom horizontal
        if (mask & 0x08) {
            dc.fillPolygon([
                [x + t * 2, y + h - t] as Array<Number>,
                [x + w - t * 2, y + h - t] as Array<Number>,
                [x + w - t, y + h] as Array<Number>,
                [x + t, y + h] as Array<Number>,
            ] as Array< Array<Number> >);
        }

        // Segment e — bottom-left vertical
        if (mask & 0x10) {
            dc.fillPolygon([
                [x, y + hh + 1] as Array<Number>,
                [x + t, y + hh + t] as Array<Number>,
                [x + t, y + h - t * 2] as Array<Number>,
                [x, y + h - t] as Array<Number>,
            ] as Array< Array<Number> >);
        }

        // Segment f — top-left vertical
        if (mask & 0x20) {
            dc.fillPolygon([
                [x, y + t] as Array<Number>,
                [x + t, y + t * 2] as Array<Number>,
                [x + t, y + hh - t] as Array<Number>,
                [x, y + hh - 1] as Array<Number>,
            ] as Array< Array<Number> >);
        }

        // Segment g — middle horizontal
        if (mask & 0x40) {
            dc.fillPolygon([
                [x + t, y + hh] as Array<Number>,
                [x + t * 2, y + hh - t / 2] as Array<Number>,
                [x + w - t * 2, y + hh - t / 2] as Array<Number>,
                [x + w - t, y + hh] as Array<Number>,
                [x + w - t * 2, y + hh + t / 2] as Array<Number>,
                [x + t * 2, y + hh + t / 2] as Array<Number>,
            ] as Array< Array<Number> >);
        }
    }

    // Draw the colon separator (two squares).
    function drawColon(dc as Dc, x as Number, y as Number,
                       h as Number, size as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var topY = y + h / 3 - size / 2;
        var botY = y + 2 * h / 3 - size / 2;
        dc.fillRectangle(x, topY, size, size);
        dc.fillRectangle(x, botY, size, size);
    }

    // Draw a full time string HH:MM or HH:MM:SS.
    // Returns total width drawn.
    function drawTime(dc as Dc, hours as Number, minutes as Number, seconds as Number?,
                      x as Number, y as Number, digitW as Number, digitH as Number,
                      thickness as Number, gap as Number, color as Number,
                      secDigitW as Number?, secDigitH as Number?, secThickness as Number?) as Number {
        var cx = x;

        // Hours
        var h1 = hours / 10;
        var h2 = hours % 10;
        drawDigit(dc, h1, cx, y, digitW, digitH, thickness, color);
        cx += digitW + gap;
        drawDigit(dc, h2, cx, y, digitW, digitH, thickness, color);
        cx += digitW + gap;

        // Colon
        var colonSize = thickness + 1;
        drawColon(dc, cx, y, digitH, colonSize, color);
        cx += colonSize + gap;

        // Minutes
        var m1 = minutes / 10;
        var m2 = minutes % 10;
        drawDigit(dc, m1, cx, y, digitW, digitH, thickness, color);
        cx += digitW + gap;
        drawDigit(dc, m2, cx, y, digitW, digitH, thickness, color);
        cx += digitW;

        // Seconds (smaller)
        if (seconds != null) {
            var sw = secDigitW != null ? secDigitW : digitW * 2 / 3;
            var sh = secDigitH != null ? secDigitH : digitH * 2 / 3;
            var st = secThickness != null ? secThickness : thickness * 2 / 3;
            if (st < 1) { st = 1; }
            var secY = y + digitH - sh; // align bottom

            cx += gap;
            // Colon
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
