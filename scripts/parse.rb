#!/usr/bin/env ruby

require 'fileutils'
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
    end

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
            recurse(doc)
        end
    end

    def parse_darc()
        system("wget -O darc.html \"https://www.darc.de/der-club/referate/ajw/darc-online-lehrgang/\"")
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

File.open('../data/questions.json', 'w') do |f|
    f.puts parser.dump.to_json
end

File.open('../data/questions.yaml', 'w') do |f|
    f.puts parser.dump.to_yaml
end
