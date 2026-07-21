{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.patrick.home.hyprland;
  latPath = config.sops.secrets."cosmic/latitude".path;
  lonPath = config.sops.secrets."cosmic/longitude".path;

  apiBase = "https://api.open-meteo.com/v1/forecast";

  wmoJq = ''
    def wmo_icon:
      if . == 0 then "☀"
      elif . == 1 then "🌤"
      elif . == 2 then "⛅"
      elif . == 3 then "☁"
      elif (. == 45 or . == 48) then "🌫"
      elif (. >= 51 and . <= 57) then "🌦"
      elif (. >= 61 and . <= 67) then "🌧"
      elif (. >= 71 and . <= 77) then "❄"
      elif (. >= 80 and . <= 82) then "🌦"
      elif (. == 85 or . == 86) then "❄"
      elif . >= 95 then "⛈"
      else "?" end;
    def wmo_desc:
      if . == 0 then "Clear"
      elif . == 1 then "Mostly clear"
      elif . == 2 then "Partly cloudy"
      elif . == 3 then "Overcast"
      elif (. == 45 or . == 48) then "Fog"
      elif (. >= 51 and . <= 55) then "Drizzle"
      elif (. == 56 or . == 57) then "Freezing drizzle"
      elif . == 61 then "Light rain"
      elif . == 63 then "Rain"
      elif . == 65 then "Heavy rain"
      elif (. == 66 or . == 67) then "Freezing rain"
      elif . == 71 then "Light snow"
      elif . == 73 then "Snow"
      elif . == 75 then "Heavy snow"
      elif . == 77 then "Snow grains"
      elif (. >= 80 and . <= 82) then "Showers"
      elif (. == 85 or . == 86) then "Snow showers"
      elif . == 95 then "Thunderstorm"
      elif (. == 96 or . == 99) then "Thunderstorm + hail"
      else "Unknown" end;
  '';

  weather = pkgs.writeShellApplication {
    name = "waybar-weather";
    runtimeInputs = with pkgs; [
      curl
      jq
      coreutils
    ];
    text = ''
      lat=$(tr -d '[:space:]' < ${latPath})
      lon=$(tr -d '[:space:]' < ${lonPath})

      if ! data=$(curl -sf --max-time 10 \
        "${apiBase}?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code&temperature_unit=fahrenheit&timezone=auto" \
        2>/dev/null); then
        printf '{"text":"","tooltip":"weather unavailable"}\n'
        exit 0
      fi

      printf '%s' "$data" | jq '
        ${wmoJq}
        .current | {
          text: "\(.weather_code | wmo_icon) \(.temperature_2m | round)°F",
          tooltip: "\(.temperature_2m | round)°F \(.weather_code | wmo_desc)"
        }
      '
    '';
  };

  forecast = pkgs.writeShellApplication {
    name = "waybar-weather-forecast";
    runtimeInputs = with pkgs; [
      curl
      jq
      coreutils
    ];
    text = ''
      lat=$(tr -d '[:space:]' < ${latPath})
      lon=$(tr -d '[:space:]' < ${lonPath})

      if ! data=$(curl -sf --max-time 15 \
        "${apiBase}?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code&hourly=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset&temperature_unit=fahrenheit&timezone=auto&forecast_days=6" \
        2>/dev/null); then
        echo "  Failed to fetch weather data."
        echo ""
        echo "  Press any key to close."
        read -rsn1 || true
        exit 0
      fi

      printf '%s' "$data" | jq -r '
        ${wmoJq}
        def fmt_12h:
          split("T")[1] | split(":") as [$h, $m] |
          ($h | tonumber) as $hr |
          if $hr == 0 then "12:\($m) AM"
          elif $hr < 12 then "\($hr):\($m) AM"
          elif $hr == 12 then "12:\($m) PM"
          else "\($hr - 12):\($m) PM" end;
        def fmt_day:
          strptime("%Y-%m-%d") | mktime | strftime("%a");

        . as $d |
        .current as $c |
        ($c.time | split("T") | .[0] + "T" + (.[1] | split(":")[0]) + ":00") as $cur_hour |
        (.hourly.time | index($cur_hour) // 0) as $i |
        (if $c.time < $d.daily.sunrise[0] then $d.daily.sunrise[0]
         else $d.daily.sunrise[1] end) as $next_sr |
        (if $c.time < $d.daily.sunset[0] then $d.daily.sunset[0]
         else $d.daily.sunset[1] end) as $next_ss |

        ([
          "",
          "  Now      \($c.temperature_2m | round)°F  \($c.weather_code | wmo_icon) \($c.weather_code | wmo_desc)",
          ""
        ] +
        (if $d.hourly.temperature_2m[$i + 2] then
          ["  +2 hrs   \($d.hourly.temperature_2m[$i + 2] | round)°F  \($d.hourly.weather_code[$i + 2] | wmo_icon) \($d.hourly.weather_code[$i + 2] | wmo_desc)"]
        else [] end) +
        (if $d.hourly.temperature_2m[$i + 4] then
          ["  +4 hrs   \($d.hourly.temperature_2m[$i + 4] | round)°F  \($d.hourly.weather_code[$i + 4] | wmo_icon) \($d.hourly.weather_code[$i + 4] | wmo_desc)"]
        else [] end) +
        [
          "",
          "  ☀ Sunrise   \($next_sr | fmt_12h)",
          "  ☾ Sunset    \($next_ss | fmt_12h)",
          "",
          "  ─── 5-Day Forecast ───"
        ] + [
          range(1; ($d.daily.time | length)) as $j |
          "  \($d.daily.time[$j] | fmt_day)   \($d.daily.temperature_2m_max[$j] | round)°/\($d.daily.temperature_2m_min[$j] | round)°  \($d.daily.weather_code[$j] | wmo_icon) \($d.daily.weather_code[$j] | wmo_desc)"
        ]) | join("\n")
      '

      echo ""
      echo "  Press any key to close."
      read -rsn1 || true
    '';
  };

  toggle = pkgs.writeShellApplication {
    name = "waybar-weather-toggle";
    runtimeInputs = with pkgs; [ jq ];
    text = ''
      if hyprctl clients -j | jq -e '.[] | select(.class == "weather-forecast")' > /dev/null 2>&1; then
        hyprctl dispatch closewindow "class:weather-forecast"
      else
        ghostty --class=weather-forecast -e waybar-weather-forecast &
        disown
      fi
    '';
  };
in
{
  config = mkIf cfg.enable {
    home.packages = [
      weather
      forecast
      toggle
    ];

    wayland.windowManager.hyprland.settings.windowrule = [
      "float,class:^(weather-forecast)$"
      "size 500 450,class:^(weather-forecast)$"
      "center,class:^(weather-forecast)$"
    ];
  };
}
