## [0.9.0] - 2026.02.12

* **BREAKING CHANGE**: Changed `Stroke.points` from `List<Offset>` to `List<StrokePoint>`
  - Each point now contains rich input data: position, pressure, pressureMin, pressureMax, tilt, orientation
  - Enables advanced features like pressure-sensitive drawing and tilt-based calligraphy effects
* Added `generatePressureSensitivePath` function for variable-width strokes based on pressure

## [0.8.0] - 2026.02.06

* Add `strokePainter` callback for custom stroke rendering with advanced visual effects (gradients, glows, shaders, etc.)

## [0.7.0] - 2026.01.29

* Add `shouldAbsorb` callback to control pointer event absorption for pan/zoom gesture on ancestor widgets, typically `InteractiveViewer`. 

## [0.6.1] - 2026.01.26

* Fixed a bug when starting strokes

## [0.6.0] - 2026.01.23

* Add `onStrokeUpdated` callback for real-time stroke manipulation during drawing

## [0.5.1] - 2026.01.21

* Fix the behavior of `ErasingBehavior.stroke`

## [0.5.0] - 2026.01.21

* (*Breaking) `isErasing` is now `ErasingBehavior`. Legacy `isErasing: true` is equivalent to `ErasingBehavior.pixel`.
* Customizable `intersectionDetector` for intersection detection when `ErasingBehaviro.stroke`.

## [0.4.3] - 2026.01.21

* Updated README.md
* Added AI_GUIDE.md

## [0.4.2] - 2026.01.20

* Fixed typo

## [0.4.1] - 2026.01.20

* Fixed lint

## [0.4.0] - 2026.01.20

* Add `onStrokeStarted` callback for flexible stroke control based on input device type

## [0.3.0] - 2026.01.16

* (*Breaking) Fully changed API design for smooth integration with your apps
* Smoothing strokes
* Enhance user interaction

## [0.2.0] - 2021.03.31

* Add feature of converting canvas to image data

## [0.1.0] - 2021.03.31

* Add clear feature

## [0.0.7] - 2021.03.31

* Add erase feature

## [0.0.6] - 2021.03.31

* Add undo / redo features

## [0.0.5] - 2021.03.30

* Update `README.md`

## [0.0.4] - 2021.03.30

* Add demo to `README.md`

## [0.0.3] - 2021.03.30

* Add configuration for colors and stroke width
* Add `DrawController`

## [0.0.2] - 2021.03.30

* Add example
* Add document comments

## [0.0.1] - 2021.03.30

* Draw only black strokes.
