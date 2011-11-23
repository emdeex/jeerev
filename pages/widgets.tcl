Jm doc "Sample widgets."

variable title "Simple widgets demo page"
variable menu "Widgets"

variable css {
  .widget {
  	display: inline-block; border: 1px solid silver; border-radius: 5px;
  }
  .widget h3 {
  	text-align: center; margin: 0 0 2px; background-color: silver;
  }
  .tempWidget {
  	font-family: sans-serif; display: inline-block; margin: 0 10px;
  }
  .tempWidget .val {
  	font-size: 24pt; float: left; font-weight: bold;
  }
  .tempWidget .dec {
  	font-size: 12pt;
  }
  .tempWidget .unit {
  	font-size: 10pt; margin-left: -10px;
  }
}

variable tmpl [Sif html {
  .widget
    h3: Woonkamer
    .tempWidget
      span.val
        : 25
        span.dec: .3
      span.unit: °C
    .tempWidget
      span.val
        : 64
        span.dec: %
      span.unit: RH
  p: 
  .widget
    h3: Stroomverbruik
    .tempWidget
      span.val
        : 672
        span.dec: W
      span.unit: nu
    .tempWidget
      span.val
        : 1368
        span.dec: W
      span.unit: 24u
  p: 
  .widget
    h3: Gasverbruik
    .tempWidget
      span.val
        : 1.26
        span.dec: m<sup>3</sup>/u
      span.unit: nu
    .tempWidget
      span.val
        : 0.27
        span.dec: m<sup>3</sup>/u
      span.unit: 24u
}]
