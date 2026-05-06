import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.Weather;

// Centralized data fetching with null safety.
// Every getter returns null if the data is unavailable.

class DataProvider {

    function getHeartRate() as Number? {
        if (Toybox has :SensorHistory && SensorHistory has :getHeartRateHistory) {
            var iter = SensorHistory.getHeartRateHistory({ :period => 1 });
            if (iter != null) {
                var sample = iter.next();
                if (sample != null && sample.data != null) {
                    return sample.data as Number;
                }
            }
        }
        return null;
    }

    function getStress() as Number? {
        if (Toybox has :ActivityMonitor) {
            var info = ActivityMonitor.getInfo();
            if (info != null && info has :stressScore && info.stressScore != null) {
                return info.stressScore as Number;
            }
        }
        return null;
    }

    function getSteps() as Number? {
        if (Toybox has :ActivityMonitor) {
            var info = ActivityMonitor.getInfo();
            if (info != null && info.steps != null) {
                return info.steps as Number;
            }
        }
        return null;
    }

    function getStepGoal() as Number? {
        if (Toybox has :ActivityMonitor) {
            var info = ActivityMonitor.getInfo();
            if (info != null && info.stepGoal != null) {
                return info.stepGoal as Number;
            }
        }
        return null;
    }

    function getAltitude() as Number? {
        if (Toybox has :SensorHistory && SensorHistory has :getElevationHistory) {
            var iter = SensorHistory.getElevationHistory({ :period => 1 });
            if (iter != null) {
                var sample = iter.next();
                if (sample != null && sample.data != null) {
                    return (sample.data as Float).toNumber();
                }
            }
        }
        return null;
    }

    function getWeatherCondition() as Number? {
        if (Toybox has :Weather && Weather has :getCurrentConditions) {
            var cond = Weather.getCurrentConditions();
            if (cond != null && cond.condition != null) {
                return cond.condition as Number;
            }
        }
        return null;
    }

    function getCurrentTemp() as Number? {
        if (Toybox has :Weather && Weather has :getCurrentConditions) {
            var cond = Weather.getCurrentConditions();
            if (cond != null && cond.temperature != null) {
                return cond.temperature as Number;
            }
        }
        return null;
    }

    function getLowTemp() as Number? {
        if (Toybox has :Weather && Weather has :getCurrentConditions) {
            var cond = Weather.getCurrentConditions();
            if (cond != null && cond.lowTemperature != null) {
                return cond.lowTemperature as Number;
            }
        }
        return null;
    }

    function getHighTemp() as Number? {
        if (Toybox has :Weather && Weather has :getCurrentConditions) {
            var cond = Weather.getCurrentConditions();
            if (cond != null && cond.highTemperature != null) {
                return cond.highTemperature as Number;
            }
        }
        return null;
    }

    function getUvIndex() as Number? {
        if (Toybox has :Weather && Weather has :getCurrentConditions) {
            var cond = Weather.getCurrentConditions();
            if (cond != null && cond has :uvIndex && cond.uvIndex != null) {
                return cond.uvIndex as Number;
            }
        }
        return null;
    }

    function getSunrise() as Time.Moment? {
        if (Toybox has :Weather && Weather has :getSunrise) {
            return Weather.getSunrise(null, null);
        }
        return null;
    }

    function getSunset() as Time.Moment? {
        if (Toybox has :Weather && Weather has :getSunset) {
            return Weather.getSunset(null, null);
        }
        return null;
    }

    function getSolarIntensity() as Number? {
        if (Toybox has :SensorHistory && SensorHistory has :getSolarIntensityHistory) {
            var iter = SensorHistory.getSolarIntensityHistory({ :period => 1 });
            if (iter != null) {
                var sample = iter.next();
                if (sample != null && sample.data != null) {
                    return (sample.data as Number);
                }
            }
        }
        return null;
    }
}
