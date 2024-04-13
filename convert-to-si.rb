#!/usr/bin/env ruby

require 'fileutils'

FileUtils.mkpath('scripts/cache/svg-scour-jovial')
Dir['scripts/cache/svg-scour/*.svg'].each_slice(500) { |x| system("dart run jovial_svg:svg_to_si --no-big -o scripts/cache/svg-scour-jovial/ #{x.join(' ')}") }
