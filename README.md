# Slic3r Post-Processing Script Template (Perl)
making it easier to write postprocessing scripts for Slic3r in Perl by providing subroutines, configurability and a buffer.

## Available subroutines
- process_start_gcode
- process_end_gcode
- process_tool_change
- process_comment
- process_layer_change
- process_retraction_move
- process_printing_move
- process_travel_move
- process_absolute_extrusion
- process_relative_extrusion
- process_other

## Printing parameter availability
- via `$parameters{"some_parameter"}`
- all parameters defined by Slic3r
- parameters you specify in your G-code comments à la `; some_parameter = 2`

## Features
- [x] Parser-Subroutines à la `process_layer_change`
- [x] Parameter accessibility à la `$parameters{"some_parameter"}`
- [x] input buffer `@inputBuffer`
- [x] output buffer `@inputBuffer`
- [ ] Printing-Subroutines (for inserting printing moves and other G-codes)

## How to use
- Add your code to the marked sections in the #Processing section of the template.
- Add `; start of print` to the beginning of your G-code (ideally at the end of your start g-code)
- Add `; end of print` to the end of your G-code (ideally at the beginning of your end g-code)
- Add absolute path to the script in Slic3r's output settings (no /~ allowed)
- Optional: Activate verbose G-code in Slic3r's output settings
- Slice!

## Disclaimer / License
This is a work in progress. Any suggestions are heavily welcome. All scripts in this repository are licensed under the GNU Affero General Public License, version 3. Created by Moritz Walter 2016.
