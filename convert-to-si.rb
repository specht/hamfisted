#!/usr/bin/env ruby

Dir['scripts/cache/svg-scour/*.svg'].each_slice(500) { |x| system("dart run jovial_svg:svg_to_si -b -o scripts/ca
che/svg-scour-jovial-32/ #{x.join(' ')}") }
