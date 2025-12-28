local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end
if not LibEKL.Tools then LibEKL.Tools = {} end

LibEKL.Tools.DateTime = {}

---------- init local variables ---------

local mathModf      = math.modf
local mathFloor     = math.floor
local osDate        = os.date
local osTime        = os.time
local stringLower   = string.lower
local stringFormat  = string.format

-- Number of days in each month.
local DAYS_IN_MONTH = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

-- Divisors for leap year calculation.
local LEAP_YEAR_DIVISOR_4 = 4
local LEAP_YEAR_DIVISOR_100 = 100
local LEAP_YEAR_DIVISOR_400 = 400

-- Constants for time calculations.
local MINUTES_IN_HOUR = 60
local HOURS_IN_DAY = 24
local SECONDS_IN_MINUTE = 60
local SECONDS_IN_HOUR = 3600

-- ========== DATE HANDLING ========== --

-- Checks if a year is a leap year.
-- @param year The year to check.
-- @return true if the year is a leap year, false otherwise.
local function isLeapYear(year)
    if (mathModf(year, LEAP_YEAR_DIVISOR_4) == 0) then
        if (mathModf(year, LEAP_YEAR_DIVISOR_100) == 0) then
            if (mathModf(year, LEAP_YEAR_DIVISOR_400) == 0) then
                return true
            end
        else
            return true
        end
    end
    return false
end

-- Gets the number of days in a month.
-- @param month The month to check.
-- @param year The year to check.
-- @return The number of days in the month.
function LibEKL.Tools.DateTime.GetDaysInMonth(month, year)
    local days = DAYS_IN_MONTH[month]

    -- Check for leap year
    if (month == 2) and isLeapYear(year) then
        days = 29
    end

    return days
end

-- Adjusts a date by a given number of days or months.
-- @param inDate The date to adjust.
-- @param adjustBy The unit to adjust by ('day' or 'month').
-- @param value The number of units to adjust by.
-- @return The adjusted date.
function LibEKL.Tools.DateTime.AdjustDate(inDate, adjustBy, value)
    local newDate
    local day, month, year = tonumber(osDate("%d", inDate)), tonumber(osDate("%m", inDate)), tonumber(osDate("%Y", inDate))

    if stringLower(adjustBy) == 'day' then

        day = day + value

        -- Handle day overflow
        if day < 1 then
            month = month -1
            if month < 1 then
                year = year - 1
                month = 12
            end

            day = LibEKL.Tools.DateTime.GetDaysInMonth(month, year) + day
        elseif day > LibEKL.Tools.DateTime.GetDaysInMonth(month, year) then
            day = day - LibEKL.Tools.DateTime.GetDaysInMonth(month, year)
            month = month + 1
            if month > 12 then
                year = year + 1
                month = 1
            end
        end

        newDate = osTime{year = year, month = month, day = day }

    elseif stringLower(adjustBy) == 'month' then

        month = month + value
        -- Handle month overflow
        if month > 12 then
            year = year + 1
            month = 1
        elseif month < 1 then
            year = year - 1
            month = 12
        end

        newDate = osTime{year = year, month = month, day = day }

    end

    return newDate

end

-- Adjusts a time by a given number of minutes.
-- @param inTime The time to adjust.
-- @param adjustBy The unit to adjust by ('min').
-- @param value The number of units to adjust by.
-- @return The adjusted time.
function LibEKL.Tools.DateTime.AdjustTime(inTime, adjustBy, value)
    local day, month, year = tonumber(osDate("%d", inTime)), tonumber(osDate("%m", inTime)), tonumber(osDate("%Y", inTime))
    local hour, minute, second = tonumber(osDate("%H", inTime)), tonumber(osDate("%M", inTime)), tonumber(osDate("%S", inTime))

    if stringLower(adjustBy) == 'min' then

        minute = minute + value
        -- Handle minute overflow
        if minute > MINUTES_IN_HOUR then
            minute = minute - MINUTES_IN_HOUR
            hour = hour + 1
            if hour > HOURS_IN_DAY - 1 then
                hour = 0
                local tempDate = osTime{year = year, month = month, day = day, hour = hour, min = minute, sec = second}
                return LibEKL.Tools.DateTime.AdjustDate(tempDate, "day", 1)
            end
        elseif minute < 0 then
            minute = MINUTES_IN_HOUR - 1 - minute
            hour = hour - 1
            if hour < 0 then
                hour = HOURS_IN_DAY - 1
                local tempDate = osTime{year = year, month = month, day = day, hour = hour, min = minute, sec = second}
                return LibEKL.Tools.DateTime.AdjustDate(tempDate, "day", -1)
            end
        end

        return osTime{year = year, month = month, day = day, hour = hour, min = minute, sec = second}

    end

    return nil

end

-- Checks if a date is in the past.
-- @param inDate The date to check.
-- @return true if the date is in the past, false otherwise.
function LibEKL.Tools.DateTime.IsDatePast(inDate)
    if LibEKL.Tools.DateTime.Today() > inDate then
        return true
    else
        return false
    end

end

-- Gets the current date.
-- @return The current date.
function LibEKL.Tools.DateTime.Today()
    return osTime{year = osDate("%Y"), month = osDate("%m"), day = osDate("%d")}
end

-- Converts seconds to a human-readable text format.
-- @param seconds The number of seconds to convert.
-- @return The human-readable text representation of the seconds.
function LibEKL.Tools.DateTime.SecondsToText(seconds)
    if seconds < 0 then
        return ""
    elseif seconds > SECONDS_IN_HOUR then
        return tostring(mathFloor(seconds / SECONDS_IN_HOUR)).."h"
    elseif seconds > SECONDS_IN_MINUTE then
        return tostring(mathFloor(seconds / SECONDS_IN_MINUTE)).."m"
    end

    return tostring(mathFloor(seconds).."s")
end