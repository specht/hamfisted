#!/usr/bin/env ruby

require 'fileutils'
require 'nokogiri'
require 'json'
require 'yaml'

FileUtils.mkpath('scripts/cache/svg-scour-jovial')
Dir['scripts/cache/svg-scour/*.svg'].each_slice(500) { |x| system("dart run jovial_svg:svg_to_si --no-big -o scripts/cache/svg-scour-jovial/ #{x.join(' ')}") }
data = YAML.load(File.read('data/questions.yaml'))
data[:questions].each_pair do |qid, info|
    if info[:challenge_tex]
        path = "scripts/cache/svg-scour/#{info[:challenge_tex]}.svg"
        svg_dom = Nokogiri::XML(File.read(path)).css('svg')
        info[:challenge_tex_width] = svg_dom.attr('width').to_s.to_f
        info[:challenge_tex_height] = svg_dom.attr('height').to_s.to_f
    end
    if info[:answers_tex]
        info[:answers_tex_width] = []
        info[:answers_tex_height] = []
        info[:answers_tex].each do |sha1|
            path = "scripts/cache/svg-scour/#{sha1}.svg"
            svg_dom = Nokogiri::XML(File.read(path)).css('svg')
            info[:answers_tex_width] << svg_dom.attr('width').to_s.to_f
            info[:answers_tex_height] << svg_dom.attr('height').to_s.to_f
        end
    end
end

File.write('data/questions.yaml', data.to_yaml)
File.write('data/questions.json', data.to_json)