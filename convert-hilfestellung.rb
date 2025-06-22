#!/usr/bin/env ruby

Dir.chdir('assets')

(1..24).each do |page|
    command = "inkscape --pdf-poppler --pdf-page=#{page} -C -o hilfsmittel-#{page}.svg Hilfsmittel.pdf"
    system(command)
    # command = "scour hilfsmittel-#{page}.svg hilfsmittel-#{page}-scour.svg"
    # system(command)
    # command = "dart run jovial_svg:svg_to_si --no-big -o ./jovial/ hilfsmittel-#{page}-scour.svg"
    # system(command)
    [150, 300].each do |dpi|
        command = "inkscape -d #{dpi} --pdf-poppler --pdf-page=#{page} -C -o hilfsmittel-#{page}-#{dpi}.png Hilfsmittel.pdf"
        system(command)
        command = "convert hilfsmittel-#{page}-#{dpi}.png -background white -flatten -quality 85 hilfsmittel-#{page}-#{dpi}.jpg"
        system(command)
        command = "rm hilfsmittel-#{page}-#{dpi}.png"
        system(command)
    end
    command = "rm hilfsmittel-#{page}.svg"
    system(command)
    # command = "rm hilfsmittel-#{page}-scour.svg"
    # system(command)
end