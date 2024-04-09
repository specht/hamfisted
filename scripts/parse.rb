#!/usr/bin/env ruby

require 'digest'
require 'fileutils'
require 'katex'
require 'nokogiri'
require 'set'
require 'json'
require 'yaml'

class Parser
    def initialize()
        @questions = {}
        @headings = {}
        @parents = {}
        @children = {}
        @questions_for_hid = {}
        @meta = []
        @children[''] = ['2007', '2024']
        @parents['2007'] = ''
        @parents['2024'] = ''
        @headings['2007'] = 'Alter Fragenkatalog (2007)'
        @headings['2024'] = 'Neuer Fragenkatalog (2024)'
        @questions_for_hid['2007'] = []
        @questions_for_hid['2024'] = []
        @latex_terms = Set.new()
    end

    attr_reader :latex_terms

    def fix_png_path(text)
        result = text.gsub(/([a-z0-9_]+\.png)/) do |x|
            match = Regexp.last_match
            'asset:data/' + match[1].sub('.png', @id_suffix + '.png')
        end
        result = result.gsub(/([a-z0-9_]+\.jpg)/) do |x|
            match = Regexp.last_match
            'asset:data/' + match[1].sub('.jpg', @id_suffix + '.jpg')
        end
        result
    end

    def recurse(node, level = 0, prefix = [])
        spacer = '  ' * level
        node.css('>chapter').each do |chapter|
            name = chapter.attr('name')
            id = chapter.attr('id')
            if level == 0
                id += @id_suffix
                name.gsub!('Prüfungsfragen im Prüfungsteil', '')
                name.gsub!('„', '')
                name.gsub!('“', '')
                name.strip!
            end
            if name.include?('Hinweis:')
                name = name[0, name.index('Hinweis:')].strip
            end
            name = name.gsub('´', '').strip
            hid = "#{(prefix + [id]).join('/')}"
            raise 'nope' if @headings.include?(hid)
            @headings[hid] = name
            parent_hid = prefix.empty? ? '' : "#{prefix.join('/')}"
            @children[parent_hid] ||= []
            @children[parent_hid] << hid
            @parents[hid] = parent_hid
            # STDERR.puts "#{spacer}[#{parent_hid}] => [#{hid}] #{name}"
            recurse(chapter, level + 1, prefix + [id])
            chapter.css('>question').each do |question|
                qid = question.attr('id')
                qid = "#{qid}#{@id_suffix}"
                data = {}
                data[:challenge] = fix_png_path(question.css('>textquestion')[0].text.strip)
                data[:answers] = []
                question.css('>textanswer').each.with_index do |answer, index|
                    if index == 0
                        if answer.attr('correct') != 'true'
                            raise 'oops'
                        end
                    end
                    data[:answers] << fix_png_path(answer.text.strip)
                end
                # STDERR.puts "#{spacer}  [#{qid}] #{data[:challenge]}"
                raise 'nope' if @questions.include?(qid)
                @questions[qid] = data
                (0..(prefix + [id]).size).each do |l|
                    sub_prefix = (prefix + [id])[0, l]
                    lhid = sub_prefix.join('/')
                    @questions_for_hid[lhid] ||= []
                    @questions_for_hid[lhid] << qid
                end
            end
        end
    end

    def parse(path, id_suffix)
        @id_suffix = id_suffix
        File.open(path) do |f|
            doc = Nokogiri::XML(f).css('aqdf')[0]
            title = doc.css('title')[0].text
            publisher = doc.css('publisher')[0].text
            version = doc.css('version')[0].text
            @meta << {:title => title, :publisher => publisher, :version => version}
            recurse(doc, 0, ['2007'])
        end
    end

    def parse_darc()
        #system("wget -O darc.html \"https://www.darc.de/der-club/referate/ajw/darc-online-lehrgang/\"")
        File.open('darc.html') do |f|
            doc = Nokogiri::HTML(f)
            doc.css('a').each do |a|
                href = a.attr('href')
                next unless href.index('https://www.darc.de/der-club/referate/ajw/lehrgang') == 0
                short = href.sub('https://www.darc.de/der-club/referate/ajw/', '')
                cat = short.split('/').first
                suffix = ''
                if cat == 'lehrgang-bv'
                elsif cat == 'lehrgang-te'
                    suffix = 'E'
                elsif cat == 'lehrgang-ta'
                    suffix = 'A'
                else
                    raise "oops: got #{short}"
                end
                qid = short.split('#').last
                qid += suffix
                if @questions.include?(qid)
                    STDERR.puts "Adding hint to #{qid}: #{href}"
                    @questions[qid][:hint] = href
                else
                    STDERR.puts "Unknown qid: #{qid}"
                end
            end
        end
    end

    def render_katex(s)
        s.gsub(/\$[^\$]+\$/) do |x|
            x = x[1, x.size - 2]
            @latex_terms << x
            # STDERR.puts x
            # exit
            sha1 = Digest::SHA1.hexdigest("#{x}/#{Katex::KATEX_VERSION}")
            unless File.exist?("cache/#{sha1}")
                File.open("cache/#{sha1}", 'w') { |f| f.write(Katex.render(x)) }
            end
            File.read("cache/#{sha1}")
        end
    end

    def recurse_json(sections, level = 0, prefix = [])
        spacer = '  ' * level
        sections.each.with_index do |section, index|
            id = "#{index}"
            hid = "#{(prefix + [id]).join('/')}"
            parent_hid = prefix.empty? ? '' : "#{prefix.join('/')}"
            title = section['title']
            title.sub!('Prüfungsfragen im Prüfungsteil: ', '')
            @headings[hid] = title
            STDERR.puts "#{spacer}[#{parent_hid}] => [#{hid}] #{title}"
            @children[parent_hid] ||= []
            @children[parent_hid] << hid
            @parents[hid] = parent_hid
            if section['sections']
                recurse_json(section['sections'], level + 1, prefix + [id])
            end
            if section['questions']
                section['questions'].each do |question|
                    qid = '2024_' + question['number']
                    qid = "#{qid}#{@id_suffix}"
                    data = {}
                    data[:challenge] = render_katex(question['question'])
                    if question['picture_question']
                        path = Dir["../bnetza-2024/svgs/#{question['picture_question']}*"].first
                        if path.include?('.svg')
                            svg = File.read(path)
                            svg_dom = Nokogiri::XML(svg).css('svg')
                            width = svg_dom.attr('width').to_s.to_f
                            height = svg_dom.attr('height').to_s.to_f
                            data[:challenge] += "<p>#{svg}</p>"
                            data[:challenge_svg_width] = width
                            data[:challenge_svg_height] = height
                        else
                            data[:challenge] += "<p><img src=\"asset:data/2024/#{File.basename(path)}\" /></p>"
                        end
                    end
                    data[:answers] = [
                        render_katex(question['answer_a']),
                        render_katex(question['answer_b']),
                        render_katex(question['answer_c']),
                        render_katex(question['answer_d']),
                    ]
                    # if qid == '2024_NH303'
                        # STDERR.puts data.to_yaml
                        # exit
                    # end
                    # data[:challenge] = fix_png_path(question.css('>textquestion')[0].text.strip)
                    # data[:answers] = []
                    # question.css('>textanswer').each.with_index do |answer, index|
                    #     if index == 0
                    #         if answer.attr('correct') != 'true'
                    #             raise 'oops'
                    #         end
                    #     end
                    #     data[:answers] << fix_png_path(answer.text.strip)
                    # end
                    # # STDERR.puts "#{spacer}  [#{qid}] #{data[:challenge]}"
                    raise 'nope' if @questions.include?(qid)
                    @questions[qid] = data
                    (0..(prefix + [id]).size).each do |l|
                        sub_prefix = (prefix + [id])[0, l]
                        lhid = sub_prefix.join('/')
                        @questions_for_hid[lhid] ||= []
                        @questions_for_hid[lhid] << qid
                    end
                end
            end
        end
    end

    def parse_2024
        data = JSON.parse(File.read('../bnetza-2024/fragenkatalog3b.json'))
        recurse_json(data['sections'], 0, ['2024'])
    end

    def dump
        {
            :meta => @meta,
            :questions => @questions,
            :headings => @headings,
            :children => @children,
            :parents => @parents,
            :questions_for_hid => @questions_for_hid
        }
    end
end

FileUtils::mkpath('../data')
parser = Parser.new()
['DL Technik Klasse E 2007', 'DL Technik Klasse A 2007', 'DL Betriebstechnik und Vorschriften 2007'].each do |_path|
    path = File.join('..', 'bnetza', _path)
    id_suffix = ''
    id_suffix = 'E' if path.include?('Klasse E')
    id_suffix = 'A' if path.include?('Klasse A')
    # STDERR.puts path
    parser.parse("#{path}/questions.xml", id_suffix)
    Dir["#{path}/*.png"].each do |path|
        FileUtils.cp(path, "../data/#{File.basename(path).sub('.png', id_suffix + '.png')}")
    end
    Dir["#{path}/*.jpg"].each do |path|
        FileUtils.cp(path, "../data/#{File.basename(path).sub('.jpg', id_suffix + '.jpg')}")
    end
end
parser.parse_darc()
parser.parse_2024()

File.open('../data/questions.json', 'w') do |f|
    f.puts parser.dump.to_json
end

File.open('../data/questions.yaml', 'w') do |f|
    f.puts parser.dump.to_yaml
end

def convert_latex(s)
    s = "#{s}"
    s.gsub!('=', '&nbsp;=&nbsp;')
    s.gsub!('-', '&ndash;')
    while s.include?('\\textrm{')
        i0 = s.index('\\textrm{')
        i1 = s.index('}', i0)
        s = s[0, i0] + s[(i0 + 8)..(i1 - 1)] + s[(i1 + 1)..-1]
    end
    while s.include?('^{')
        i0 = s.index('^{')
        i1 = s.index('}', i0)
        s = s[0, i0] + '<sup>' + s[(i0 + 2)..(i1 - 1)] + '</sup>' + s[(i1 + 1)..-1]
    end
    while s.include?('^')
        i0 = s.index('^')
        s = s[0, i0] + '<sup>' + s[(i0 + 1)..(i0 + 1)] + '</sup>' + s[(i0 + 2)..-1]
    end
    while s.include?('_{')
        i0 = s.index('_{')
        i1 = s.index('}', i0)
        s = s[0, i0] + '<sub>' + s[(i0 + 2)..(i1 - 1)] + '</sub>' + s[(i1 + 1)..-1]
    end
    while s.include?('_')
        i0 = s.index('_')
        s = s[0, i0] + '<sub>' + s[(i0 + 1)..(i0 + 1)] + '</sub>' + s[(i0 + 2)..-1]
    end
    s.gsub!('\\frac{', '\\dfrac{')
    while s.include?('\\dfrac{')
        i0 = s.index('\\dfrac{')
        i1 = s.index('}', i0)
        upper = s[(i0 + 7)..(i1 - 1)]
        i2 = i1 + 1
        i3 = s.index('}', i2)
        lower = s[(i2 + 1)..(i3 - 1)]
        s = s[0, i0] + "<span class='frac'><span>#{upper}</span><span>#{lower}</span></span>" + s[(i3 + 1)..-1]
    end
    while s.include?('\\sqrt{')
        i0 = s.index('\\sqrt{')
        i1 = s.index('}', i0)
        s = s[0, i0] + '√' + s[(i0 + 6)..(i1 - 1)] + s[(i1 + 1)..-1]
    end

    s.gsub!('\\cdot', ' &middot; ')
    s.gsub!('\\Omega', '&nbsp;&Omega;')
    s.gsub!('\\pi', '&pi;')
    s.gsub!('\\varphi', '𝜑')
    s.gsub!('\\phi', 'ϕ')
    s.gsub!('\\lambda', '&lambda;')
    s.gsub!('\\ll', '&nbsp;≪&nbsp;')
    s.gsub!('\\gg', '&nbsp;≫&nbsp;')
    "<span class='eq'>&nbsp;#{s}&nbsp;</span>"
end

File.open('../data/latex_terms.html', 'w') do |f|
    f.puts <<~END_OF_STRING
    <style>
        .eq {
            display: inline-flex;
            font-family: 'Alegreya';
            border: 1px solid red;
            align-items: center;
            /* gap: 0.2em; */
        }
        .frac {
            display: inline-block;
        }
        .frac > span:first-child {
            border-bottom: 1px solid black;
        }
        .frac > span {
            display: block;
            text-align: center;
        }
        .eq sub {
            font-size: 60%;
            padding-top: 1em;
        }
        .eq sup {
            font-size: 60%;
            padding-bottom: 1em;
        }
    </style>
    END_OF_STRING
    f.puts "<table><tr><th>Term</th><th>Converted</th></tr>"
    parser.latex_terms.to_a.each do |x|
        f.puts "<tr>"
        f.puts "<td style='max-width: 20em; font-family: monospace;'>#{x}</td>"
        f.puts "<td>blabla #{convert_latex(x)} blabla</td>"
        f.puts "</tr>"
    end
    f.puts "</table>"
end