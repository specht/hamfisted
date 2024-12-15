#!/usr/bin/env ruby

require 'digest'
require 'fileutils'
require 'nokogiri'
require 'set'
require 'json'
require 'yaml'

SKIP_SVG = true

class Parser
    def initialize()
        @questions = {}
        @headings = {}
        @parents = {}
        @children = {}
        @questions_for_hid = {}
        @hid_for_question = {}
        @meta = []
        @children[''] = ['2007', '2024']
        @children['2024'] = ['2024/TN', '2024/TE', '2024/TA', '2024/TE_only', '2024/TA_only']
        @parents['2007'] = ''
        @parents['2024'] = ''
        @parents['2024/TN'] = '2024'
        @parents['2024/TE'] = '2024'
        @parents['2024/TA'] = '2024'
        @parents['2024/TE_only'] = '2024'
        @parents['2024/TE_only'] = '2024'
        @headings['2007'] = 'Alter Fragenkatalog (2007)'
        @headings['2024'] = 'Gesamter Fragenkatalog (2024)'
        @headings['2024/TN'] = 'Technische Kenntnisse der Klasse N'
        @headings['2024/TE'] = 'Technische Kenntnisse der Klassen E und N'
        @headings['2024/TA'] = 'Technische Kenntnisse der Klassen A, E und N'
        @headings['2024/TE_only'] = 'Nur Klasse E (ohne N)'
        @headings['2024/TA_only'] = 'Nur Klasse A (ohne N und E)'
        @questions_for_hid['2007'] = Set.new()
        @questions_for_hid['2024'] = Set.new()
        @questions_for_hid['2024/TN'] = Set.new()
        @questions_for_hid['2024/TE'] = Set.new()
        @questions_for_hid['2024/TA'] = Set.new()
        @questions_for_hid['2024/TE_only'] = Set.new()
        @questions_for_hid['2024/TA_only'] = Set.new()
        @latex_terms = Set.new()
        @faulty_keys = Set.new()
        @latex_entries = {}
        @latex_entry_order = []
        @latex_suffix_for_sha1 = {}
    end

    attr_reader :faulty_keys

    def latex_to_html(s)
        s = "#{s}"
        @latex_terms << s
        s.gsub!('=', '&nbsp;=&nbsp;')
        s.gsub!('>', '&nbsp;>&nbsp;')
        s.gsub!('<', '&nbsp;<&nbsp;')
        s.gsub!('-', '&ndash;')
        s.gsub!('^\\circ', '°')
        while s.include?('\\textrm{')
            i0 = s.index('\\textrm{')
            i1 = s.index('}', i0)
            s = s[0, i0] + s[(i0 + 8)..(i1 - 1)] + s[(i1 + 1)..-1]
        end
        while s.include?('\\mathrm{')
            i0 = s.index('\\mathrm{')
            i1 = s.index('}', i0)
            s = s[0, i0] + s[(i0 + 8)..(i1 - 1)] + s[(i1 + 1)..-1]
        end
        while s.include?('\\text{')
            i0 = s.index('\\text{')
            i1 = s.index('}', i0)
            s = s[0, i0] + s[(i0 + 6)..(i1 - 1)] + s[(i1 + 1)..-1]
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
        s.gsub!('\\Omega', '&Omega;')
        s.gsub!('\\pi', '&pi;')
        s.gsub!('\\varphi', '𝜑')
        s.gsub!('\\phi', 'ϕ')
        s.gsub!('\\lambda', '&lambda;')
        s.gsub!('\\delta', '&delta;')
        s.gsub!('\\eta', '&eta;')
        s.gsub!('\\approx', '&approx;')
        s.gsub!('\\infty', '&infin;')
        s.gsub!('\\ll', '&nbsp;≪&nbsp;')
        s.gsub!('\\gg', '&nbsp;≫&nbsp;')
        s.gsub!('\\left(', "<span style='transform: scale(1, 3); margin: 0 0.1em;'>(</span>")
        s.gsub!('\\right)', "<span style='transform: scale(1, 3); margin: 0 0.1em;'>)</span>")
        "<span class='eq' style='border: 1px solid green;'>&#8203;#{s}&#8203;</span>"
    end

    def render_latex(s)
        s
        # s.gsub(/\$[^\$]+\$/) do |x|
        #     x = x[1, x.size - 2]
        #     # @latex_terms << x
        #     # latex_to_html(x)
        #     "<tex>#{x}</tex>"
        # end
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
                    @questions_for_hid[lhid] ||= Set.new()
                    @questions_for_hid[lhid] << qid
                    @hid_for_question[qid] = lhid
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
        # system("wget -O darc.html \"https://www.darc.de/der-club/referate/ajw/darc-online-lehrgang/\"")
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
                    # STDERR.puts "Adding hint to #{qid}: #{href}"
                    @questions[qid][:hint] = href
                else
                    STDERR.puts "Unknown qid: #{qid}"
                end
            end
        end
    end

    def render_tex(s, key, suffix, width)
        s.gsub!('<u>', '\\underline{')
        s.gsub!('</u>', '}')
        s.gsub!('μ', '\\textmu{}')

        s.gsub!('Amateurfunkprüfungsbescheinigung', 'Ama\\-teur\\-funk\\-prü\\-fungs\\-be\\-schei\\-ni\\-gung')
        s.gsub!('Rauschunterdrückungsverfahren', 'Rausch\\-un\\-ter\\-drü\\-ckungs\\-ver\\-fah\\-ren')
        s.gsub!('Spiegelfrequenzunterdrückung', 'Spie\\-gel\\-fre\\-quenz\\-un\\-ter\\-drü\\-ckung')
        s.gsub!('Amateurfunkfrequenzbereiche', 'Ama\\-teur\\-funk\\-fre\\-quenz\\-be\\-rei\\-che')
        s.gsub!('Immissionsschutzgesetzes', 'Im\\-mis\\-si\\-ons\\-schutz\\-ge\\-set\\-zes')
        s.gsub!('Antenneneingangsimpedanz', 'An\\-ten\\-nen\\-ein\\-gangs\\-im\\-pe\\-danz')
        s.gsub!('Gleichstromeingangsleistung', 'Gleich\\-strom\\-ein\\-gangs\\-leis\\-tung')
        s.gsub!('Spannungsversorgungsleitung', 'Spannungs\\-ver\\-sor\\-gungs\\-lei\\-tung')
        s.gsub!('Amateurfunksendeantennen', 'Ama\\-teur\\-funk\\-sen\\-de\\-an\\-ten\\-nen')
        s.gsub!('Antenneneingangsimpedanz', 'An\\-ten\\-nen\\-ein\\-gangs\\-im\\-pe\\-danz')
        s.gsub!('Widerstandstransformation', 'Wider\\-stands\\-trans\\-for\\-ma\\-ti\\-on')
        s.gsub!('Leistungsverstärkerstufen', 'Leis\\-tungs\\-ver\\-stär\\-ker\\-stu\\-fen')
        s.gsub!('Antennenzuführungskabel', 'An\\-ten\\-nen\\-zu\\-füh\\-rungs\\-ka\\-bel')
        s.gsub!('Antenneneingangsleistung', 'An\\-ten\\-nen\\-ein\\-gangs\\-leis\\-tung')
        s.gsub!('Frequenzmultiplexverfahren', 'Frequenz\\-multi\\-plex\\-ver\\-fahren')
        s.gsub!('Oberwellenunterdrückung', 'Ober\\-wel\\-len\\-un\\-ter\\-drü\\-ckung')
        s.gsub!('Antennenkoaxialkabels', 'An\\-ten\\-nen\\-ko\\-axi\\-al\\-ka\\-bels')
        s.gsub!('Kohleschichtwiderständen', 'Koh\\-le\\-schicht\\-wider\\-stän\\-den')
        s.gsub!('Transformationsleitung', 'Trans\\-for\\-ma\\-ti\\-ons\\-lei\\-tung')
        s.gsub!('Immissionsschutzgesetz', 'Im\\-mis\\-si\\-ons\\-schutz\\-ge\\-setz')
        s.gsub!('Amateurfunkgenehmigung', 'Ama\\-teur\\-funk\\-ge\\-neh\\-mi\\-gung')
        s.gsub!('Modulationsverfahren', 'Mo\\-du\\-la\\-ti\\-ons\\-ver\\-fah\\-ren')
        s.gsub!('Amateurfunksatelliten', 'Ama\\-teur\\-funk\\-sa\\-tel\\-li\\-ten')
        s.gsub!('Amateurfunkregelungen', 'Ama\\-teur\\-funk\\-re\\-ge\\-lun\\-gen')
        s.gsub!('Amateurfunkhandbüchern', 'Ama\\-teur\\-funk\\-hand\\-bü\\-chern')
        s.gsub!('Senderausgangsleistung', 'Sen\\-der\\-aus\\-gangs\\-leis\\-tung')
        s.gsub!('Amateurfunkfrequenzen', 'Ama\\-teur\\-funk\\-fre\\-quen\\-zen')
        s.gsub!('Amateurfunkwettbewerb', 'Ama\\-teur\\-funk\\-wett\\-be\\-werb')
        s.gsub!('Amateurfunkzeugnissen', 'Ama\\-teur\\-funk\\-zeug\\-nis\\-sen')
        s.gsub!('Amateurfunkverordnung', 'Ama\\-teur\\-funk\\-ver\\-ord\\-nung')
        s.gsub!('Amateurfunkverbindung', 'Ama\\-teur\\-funk\\-ver\\-bin\\-dung')
        s.gsub!('Prüfungsbescheinigung', 'Prü\\-fungs\\-be\\-schei\\-ni\\-gung')
        s.gsub!('Halbleitermaterialien', 'Halb\\-lei\\-ter\\-ma\\-teri\\-alien')
        s.gsub!('Übertragungsverfahren', 'Über\\-tra\\-gungs\\-ver\\-fah\\-ren')
        s.gsub!('Amateurfunkempfängers', 'Ama\\-teur\\-funk\\-emp\\-fän\\-gers')
        s.gsub!('Telefonieverbindung', 'Te\\-le\\-fo\\-nie\\-ver\\-bin\\-dung')
        s.gsub!('Gleichstromverstärkung', 'Gleich\\-strom\\-ver\\-stär\\-kung')
        s.gsub!('Amateurfunkzulassung', 'Ama\\-teur\\-funk\\-zu\\-las\\-sung')
        s.gsub!('Amateurfunkverbandes', 'Ama\\-teur\\-funk\\-ver\\-ban\\-des')
        s.gsub!('Amateurfunkempfänger', 'Ama\\-teur\\-funk\\-emp\\-fän\\-ger')
        s.gsub!('Leistungsreduzierung', 'Leis\\-tungs\\-re\\-du\\-zie\\-rung')
        s.gsub!('Gleichstromversorgung', 'Gleich\\-strom\\-ver\\-sor\\-gung')
        s.gsub!('Spannungsschwankungen', 'Span\\-nungs\\-schwan\\-kun\\-gen')
        s.gsub!('Spannungsunterschiede', 'Span\\-nungs\\-un\\-ter\\-schiede')
        s.gsub!('Amateurfunkgesetzes', 'Ama\\-teur\\-funk\\-ge\\-set\\-zes')
        s.gsub!('Amateurfunkverbände', 'Ama\\-teur\\-funk\\-ver\\-bän\\-de')
        s.gsub!('Trägerunterdrückung', 'Trä\\-ger\\-un\\-ter\\-drü\\-ckung')
        s.gsub!('Spannungsmessgeräte', 'Span\\-nungs\\-mess\\-ge\\-rä\\-te')
        s.gsub!('Verzögerungsleitung', 'Ver\\-zö\\-ge\\-rungs\\-lei\\-tung')
        s.gsub!('Leistungsverstärkers', 'Leis\\-tungs\\-ver\\-stär\\-kers')
        s.gsub!('Modulationsgrades', 'Mo\\-du\\-la\\-ti\\-ons\\-gra\\-des')
        s.gsub!('Halbleitergrundstoff', 'Halb\\-lei\\-ter\\-grund\\-stoff')
        s.gsub!('Amateurfunkantenne', 'Ama\\-teur\\-funk\\-an\\-ten\\-ne')
        s.gsub!('Amateurfunkanlagen', 'Ama\\-teur\\-funk\\-an\\-la\\-gen')
        s.gsub!('Festspannungsregler', 'Fest\\-span\\-nungs\\-re\\-gler')
        s.gsub!('Amateurfunkdienstes', 'Ama\\-teur\\-funk\\-dien\\-stes')
        s.gsub!('Spannungsfestigkeit', 'Span\\-nungs\\-fes\\-tig\\-keit')
        s.gsub!('Sicherheitsabstände', 'Sicher\\-heits\\-ab\\-stän\\-de')
        s.gsub!('Wechselstromleitung', 'Wech\\-sel\\-strom\\-lei\\-tung')
        s.gsub!('Leistungsverstärker', 'Leis\\-tungs\\-ver\\-stär\\-ker')
        s.gsub!('Halbleiterkristalls', 'Halb\\-lei\\-ter\\-kris\\-talls')
        s.gsub!('Spannungsverteilung', 'Span\\-nungs\\-ver\\-tei\\-lung')
        s.gsub!('Übertragungsleitung', 'Über\\-tra\\-gungs\\-lei\\-tung')
        s.gsub!('Amateurfunkanlage', 'Ama\\-teur\\-funk\\-an\\-la\\-ge')
        s.gsub!('Leistungsanpassung', 'Leis\\-tungs\\-an\\-pas\\-sung')
        s.gsub!('Amateurfunkzeugnis', 'Ama\\-teur\\-funk\\-zeug\\-nis')
        s.gsub!('Amateurfunkbetrieb', 'Ama\\-teur\\-funk\\-be\\-trieb')
        s.gsub!('Halbleitersubstrat', 'Halb\\-lei\\-ter\\-sub\\-strat')
        s.gsub!('Temperaturregler', 'Tem\\-pe\\-ra\\-tur\\-re\\-gler')
        s.gsub!('Anzeigeverfahren', 'An\\-zei\\-ge\\-ver\\-fah\\-ren')
        s.gsub!('Spannungsversorgung', 'Spannungs\\-ver\\-sor\\-gung')
        s.gsub!('Antennenimpedanz', 'An\\-ten\\-nen\\-im\\-pe\\-danz')
        s.gsub!('Empfangsstörungen', 'Emp\\-fangs\\-stö\\-run\\-gen')
        s.gsub!('Amateurfunkstelle', 'Ama\\-teur\\-funk\\-stel\\-le')
        s.gsub!('Amateurfunkgesetz', 'Ama\\-teur\\-funk\\-ge\\-setz')
        s.gsub!('Amateurfunkklasse', 'Ama\\-teur\\-funk\\-klas\\-se')
        s.gsub!('Anwendungsbereich', 'An\\-wen\\-dungs\\-be\\-reich')
        s.gsub!('Signalübertragung', 'Si\\-gnal\\-über\\-tra\\-gung')
        s.gsub!('Antennenanschluss', 'An\\-ten\\-nen\\-an\\-schluss')
        s.gsub!('wissenschaftliche', 'wis\\-sen\\-schaft\\-li\\-che')
        s.gsub!('Amateurfunkbänder', 'Ama\\-teur\\-funk\\-bän\\-der')
        s.gsub!('Verstärkerelement', 'Ver\\-stär\\-ker\\-ele\\-ment')
        s.gsub!('Antennenstandrohr', 'An\\-ten\\-nen\\-stand\\-rohr')
        s.gsub!('Rundfunkempfänger', 'Rund\\-funk\\-emp\\-fän\\-ger')
        s.gsub!('Sicherheitsabstand', 'Sicher\\-heits\\-ab\\-stand')
        s.gsub!('Antennendiagrammen', 'An\\-ten\\-dia\\-gram\\-men')
        s.gsub!('Übertragungskanals', 'Über\\-tra\\-gungs\\-kanals')
        s.gsub!('Antennenanlagen', 'An\\-ten\\-nen\\-an\\-la\\-gen')
        s.gsub!('Fernsehempfänger', 'Fern\\-seh\\-emp\\-fän\\-ger')
        s.gsub!('synchronisierten', 'syn\\-chro\\-ni\\-sier\\-ten')
        s.gsub!('Empfängereingang', 'Emp\\-fän\\-ger\\-ein\\-gang')
        s.gsub!('Amateurfunkdienst', 'Ama\\-teur\\-funk\\-dienst')
        s.gsub!('Spannungsverlaufs', 'Span\\-nungs\\-ver\\-laufs')
        s.gsub!('Rufzeichenliste', 'Ruf\\-zei\\-chen\\-lis\\-te')
        s.gsub!('Empfangsantenne', 'Emp\\-fangs\\-an\\-ten\\-ne')
        s.gsub!('Antenneneingang', 'An\\-ten\\-nen\\-ein\\-gang')
        s.gsub!('Handfunkgerätes', 'Hand\\-funk\\-ge\\-rä\\-tes')
        s.gsub!('wirtschaftlichen', 'wirt\\-schaft\\-li\\-chen')
        s.gsub!('Ausgangsleistung', 'Aus\\-gangs\\-leis\\-tung')
        s.gsub!('Eingangsleistung', 'Ein\\-gangs\\-leis\\-tung')
        s.gsub!('Drahtdurchmesser', 'Draht\\-durch\\-mes\\-ser')
        s.gsub!('Steckverbindungs', 'Steck\\-ver\\-bin\\-dungs')
        s.gsub!('Feldkomponente', 'Feld\\-kom\\-po\\-nen\\-te')
        s.gsub!('Überlagerungen', 'Über\\-la\\-ge\\-run\\-gen')
        s.gsub!('Dämpfungsfaktor', 'Dämp\\-fungs\\-fak\\-tor')
        s.gsub!('Amateurfunkband', 'Ama\\-teur\\-funk\\-band')
        s.gsub!('Spannungsquelle', 'Span\\-nungs\\-quel\\-le')
        s.gsub!('Personenschutz', 'Per\\-so\\-nen\\-schutz')
        s.gsub!('Schleifendipol', 'Schleif\\-en\\-di\\-pol')
        s.gsub!('Ausgangssignal', 'Aus\\-gangs\\-si\\-gnal')
        s.gsub!('Eingangssignal', 'Ein\\-gangs\\-si\\-gnal')
        s.gsub!('Zweiseitenband', 'Zwei\\-sei\\-ten\\-band')
        s.gsub!('Funkamateure', 'Funk\\-am\\-a\\-teu\\-re')
        s.gsub!('Wasserfahrzeugs', 'Wasser\\-fahr\\-zeugs')
        s.gsub!('Transformator', 'Trans\\-for\\-ma\\-tor')
        s.gsub!('Speiseleitung', 'Spei\\-se\\-lei\\-tung')
        s.gsub!('Sendeanlage', 'Sen\\-de\\-an\\-la\\-ge')
        s.gsub!('buchstabigen', 'buch\\-sta\\-bi\\-gen')
        s.gsub!('Umwegleitung', 'Um\\-weg\\-lei\\-tung')
        s.gsub!('Verbindungen', 'Ver\\-bin\\-dun\\-gen')
        s.gsub!('Aufbereitung', 'Auf\\-be\\-rei\\-tung')
        s.gsub!('Modulation', 'Mo\\-du\\-la\\-ti\\-on')
        s.gsub!('Doppelsuper', 'Dop\\-pel\\-su\\-per')
        s.gsub!('Expeditionen', 'Ex\\-pedi\\-tionen')
        s.gsub!('Nutzfrequenz', 'Nutz\\-fre\\-quenz')
        s.gsub!('Oszillator', 'Os\\-zil\\-la\\-tor')
        s.gsub!('Bandgrenzen', 'Band\\-gren\\-zen')
        s.gsub!('Transceiver', 'Trans\\-cei\\-ver')
        s.gsub!('Stromdichte', 'Strom\\-dich\\-te')
        s.gsub!('Übertragung', 'Über\\-tra\\-gung')
        s.gsub!('Amateurfunk', 'Ama\\-teur\\-funk')
        s.gsub!('Verstärkers', 'Ver\\-stär\\-kers')
        s.gsub!('Stationen', 'Sta\\-ti\\-o\\-nen')
        s.gsub!('zulässige', 'zu\\-läs\\-si\\-ge')
        s.gsub!('Germanium', 'Ger\\-ma\\-ni\\-um')
        s.gsub!('gewerblich', 'ge\\-werb\\-lich')
        s.gsub!('Verordnung', 'Ver\\-ord\\-nung')
        s.gsub!('Aussendung', 'Aus\\-sen\\-dung')
        s.gsub!('mindestens', 'min\\-des\\-tens')
        s.gsub!('Empfehlung', 'Emp\\-feh\\-lung')
        s.gsub!('Halbleiter', 'Halb\\-lei\\-ter')
        s.gsub!('Verstärker', 'Ver\\-stär\\-ker')
        s.gsub!('Bandbreite', 'Band\\-brei\\-te')
        s.gsub!('Gleichstrom', 'Gleich\\-strom')
        s.gsub!('Groundplane', 'Ground\\-plane')
        s.gsub!('Konferenz', 'Kon\\-fe\\-renz')
        s.gsub!('Mobilfunk', 'Mo\\-bil\\-funk')
        s.gsub!('Anwendung', 'An\\-wen\\-dung')
        s.gsub!('Empfänger', 'Emp\\-fän\\-ger')
        s.gsub!('Schmalband', 'Schmal\\-band')
        s.gsub!('Sprechfunk', 'Sprech\\-funk')
        s.gsub!('Regionen', 'Re\\-gio\\-nen')
        s.gsub!('Spannungs', 'Span\\-nungs')
        s.gsub!('rufende', 'ru\\-fen\\-de')
        s.gsub!('Antenne', 'An\\-ten\\-ne')
        s.gsub!('Anzeige', 'An\\-zei\\-ge')
        s.gsub!('Bandplan', 'Band\\-plan')
        s.gsub!('Leistung', 'Leis\\-tung')
        s.gsub!('bestimmt', 'be\\-stimmt')
        s.gsub!('Windom', 'Win\\-dom')
        s.gsub!('Analog', 'Ana\\-log')

        s.gsub!('%', '\\%')
        s.gsub!('\\mOhm', 'm$\\Omega$')
        s.gsub!('\\milliOhm', 'm$\\Omega$')
        s.gsub!('\\kiloOhm', 'k$\\Omega$')
        s.gsub!('\\glqq', '"')
        key_with_suffix = "#{key}_#{suffix}"
        sha1 = Digest::SHA1.hexdigest(s)[0, 12]
        unless @latex_entries.include?(sha1)
            # if sha1 == '64b497324e5d'
                @latex_entries[sha1] = s
                @latex_entry_order << sha1
                @latex_suffix_for_sha1[sha1] = suffix
            # end
        end
        sha1
    end

    def recurse_json(sections, level = 0, prefix = [])
        spacer = '  ' * level
        sections.each.with_index do |section, index|
            id = "#{index}"
            hid = "#{(prefix + [id]).join('/')}"
            parent_hid = prefix.empty? ? '' : "#{prefix.join('/')}"
            title = section['title']
            title.sub!('Prüfungsfragen im Prüfungsteil: ', '')
            # STDERR.puts "#{spacer}[#{parent_hid}] => [#{hid}] #{title}"
            @headings[hid] = title
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

                    # next unless qid == '2024_VC102'
                    data = {}
                    # STDERR.puts "-" * 30 + qid + "-" * 30
                    data[:challenge_tex] = render_tex("\\textbf{#{question['number']}}~~~#{question['question']}", question['number'], 'q', 11)
                    # data[:challenge] = render_latex(question['question'])
                    if question['picture_question']
                        path = Dir["../bnetza-2024/svgs/#{question['picture_question']}*"].sort.first
                        if path.include?('.svg')
                            svg_dom = Nokogiri::XML(File.read(path)).css('svg')
                            data[:challenge_svg] = File.basename(path)
                            data[:challenge_svg_width] = svg_dom.attr('width').to_s.to_f
                            data[:challenge_svg_height] = svg_dom.attr('height').to_s.to_f
                        else
                            data[:challenge_png] = File.basename(path)
                        end
                    end
                    if (question['answer_a'] || '').empty? && (question['answer_b'] || '').empty? &&
                       (question['answer_c'] || '').empty? && (question['answer_d'] || '').empty?
                        data[:answers_svg] = []
                        data[:answers_svg_width] = []
                        data[:answers_svg_height] = []
                        ['a', 'b', 'c', 'd'].each do |letter|
                            path = '../bnetza-2024/svgs/' + question['picture_' + letter] + '.svg'
                            data[:answers_svg] << File.basename(path)
                            svg_dom = Nokogiri::XML(File.read(path)).css('svg')
                            data[:answers_svg_width] << svg_dom.attr('width').to_s.to_f
                            data[:answers_svg_height] << svg_dom.attr('height').to_s.to_f
                        end
                    else
                        data[:answers_tex] = [
                            render_tex(question['answer_a'], question['number'], 'a', 9.5),
                            render_tex(question['answer_b'], question['number'], 'a', 9.5),
                            render_tex(question['answer_c'], question['number'], 'a', 9.5),
                            render_tex(question['answer_d'], question['number'], 'a', 9.5),
                        ]
                        data[:answers_tex_width] = []
                        data[:answers_tex_height] = []
                        data[:answers_tex].each do |sha1|
                            # path = './cache/' + sha1 + '.svg'
                            # svg_dom = Nokogiri::XML(File.read(path)).css('svg')
                            # data[:answers_tex_width] << svg_dom.attr('width').to_s.to_f
                            # data[:answers_tex_height] << svg_dom.attr('height').to_s.to_f
                        end
                    end
                    raise 'nope' if @questions.include?(qid)
                    @questions[qid] = data

                    if prefix.first == '2024' && prefix[1] == '0'
                        classes = ['N', 'E', 'A'][question['class'].to_i - 1, 3]
                        classes << 'E_only' if question['class'] == '2'
                        classes << 'A_only' if question['class'] == '3'
                        classes.each do |c|

                            insert_id = "T#{c}"
                            sub_prefix = prefix + [id]
                            sub_prefix[1] = insert_id
                            lhid = sub_prefix.join('/')
                            lparent_hid = sub_prefix[0, sub_prefix.size - 1].join('/')

                            lhid_parts = lhid.split('/')
                            (3..lhid_parts.size).each do |j|
                                sub_parts = lhid_parts[0, j]
                                sub_hid = sub_parts.join('/')
                                sub_parent = sub_parts[0, sub_parts.size - 1].join('/')
                                @children[sub_parent] ||= []
                                @children[sub_parent] << sub_hid unless @children[sub_parent].include?(sub_hid)
                                @parents[sub_hid] = sub_parent
                                patched_sub_hid = sub_hid.split('/')
                                patched_sub_hid[1] = '0'
                                @headings[sub_hid] = @headings[patched_sub_hid.join('/')]
                            end

                            @headings[lhid] = title
                            @children[lparent_hid] ||= []
                            @children[lparent_hid] << lhid unless @children[lparent_hid].include?(lhid)
                            @parents[lhid] = lparent_hid
                            (0..(prefix + [id]).size).each do |l|
                                sub_prefix = (prefix + [id])[0, l]
                                sub_prefix[1] = insert_id
                                lhid = sub_prefix.join('/')
                                lparent_hid = sub_prefix[0, sub_prefix.size - 1].join('/')
                                @questions_for_hid[lhid] ||= Set.new()
                                @questions_for_hid[lhid] << qid
                                @hid_for_question[qid] = lhid unless lhid.include?('_only')
                            end
                        end
                    else
                        (0..(prefix + [id]).size).each do |l|
                            sub_prefix = (prefix + [id])[0, l]
                            lhid = sub_prefix.join('/')
                            @questions_for_hid[lhid] ||= Set.new()
                            @questions_for_hid[lhid] << qid
                            @hid_for_question[qid] = lhid unless lhid.include?('_only')
                        end
                    end
                end
            end
        end
    end

    def parse_2024
        data = JSON.parse(File.read('../bnetza-2024/fragenkatalog3b.json'))
        recurse_json(data['sections'], 0, ['2024'])
    end

    def finalize
        File.open("cache/all.tex", 'w') do |f|
            f.puts <<~END_OF_STRING
                \\documentclass{article}
                \\usepackage[paperwidth=9.5cm,paperheight=17cm,margin=1cm]{geometry}
                \\usepackage[utf8]{inputenc}
                \\usepackage[german]{babel}
                \\usepackage[bitstream-charter]{mathdesign}
                \\usepackage{textcomp}
                \\let\\circledS\\undefined
                \\usepackage{amsmath,amssymb,amsfonts,amsthm}
                \\usepackage{tikz}
                \\usepackage{setspace}
                \\usepackage{csquotes}
                \\usepackage{tabto}
                %\\usepackage{linebreaker}
                \\MakeOuterQuote{"}
                \\setstretch{1.15}
                \\pagestyle{empty}
                \\usepackage{fontspec}
                \\usepackage{ragged2e}
                \\setmainfont[
                BoldFont=AlegreyaSans-Bold.ttf,
                ItalicFont=AlegreyaSans-Italic.ttf,
                ]{AlegreyaSans-Regular.ttf}
                \\usepackage{mathastext}


                \\begin{document}
                \\setlength{\\parindent}{0pt}
                \\setlength{\\JustifyingParindent}{0pt}
                \\pretolerance=6000
                \\tolerance=9500
                \\hbadness=9500
                \\hfuzz5pt
                \\emergencystretch=0em
                \\justifying

            END_OF_STRING
            @latex_entry_order.each do |sha1|
                if @latex_suffix_for_sha1[sha1] != 'q'
                    f.puts "\\newgeometry{margin=1.5cm}"
                else
                    f.puts "\\newgeometry{margin=1cm}"
                end
                f.puts <<~END_OF_STRING
                    \\begin{tikzpicture}
                    \\draw [line width=0.01pt, opacity=0.01] (0,0) -- (\\textwidth,0);
                    \\end{tikzpicture}
                END_OF_STRING
                f.puts
                f.puts @latex_entries[sha1]
                f.puts
                f.puts <<~END_OF_STRING
                    \\vspace*{-2mm}
                    \\begin{tikzpicture}
                    \\draw [line width=0.01pt, opacity=0.01] (0,0) -- (\\textwidth,0);
                    \\end{tikzpicture}
                END_OF_STRING
            end
            # f.puts "\\newgeometry{margin=1cm}"
            # @latex_entry_order.each do |sha1|
            #     next unless @latex_suffix_for_sha1[sha1] == 'q'
            #     f.puts
            #     f.puts @latex_entries[sha1]
            #     f.puts
            # end
            # f.puts "\\newgeometry{margin=1.5cm}"
            # @latex_entry_order.each do |sha1|
            #     next unless @latex_suffix_for_sha1[sha1] != 'q'
            #     f.puts
            #     f.puts @latex_entries[sha1]
            #     f.puts
            # end
            f.puts <<~END_OF_STRING
                \\end{document}
            END_OF_STRING
        end
        unless SKIP_SVG
            system("docker run --rm -v ./cache:/app texlive/texlive lualatex --output-directory=/app -interaction=nonstopmode /app/all.tex")
            if $?.exitstatus != 0
                raise 'oops'
            end
        end

        cores = 8
        queues = []
        cores.times { queues << [] }
        @latex_entry_order.each.with_index do |sha1, index|
            queues[index % cores] << [sha1, index]
            # system("docker run --rm -v ./cache:/app -w /app minidocks/inkscape -o /app/svg/#{sha1}.svg --export-plain-svg --pdf-poppler --export-area-drawing --pdf-page #{index + 1} /app/all.pdf")
            # system("scour -i \"cache/svg/#{sha1}.svg\" -o \"cache/svg-scour/#{sha1}.svg\" --enable-viewboxing --enable-id-stripping --enable-comment-stripping --shorten-ids --indent=none")

            # 2.9 k instead of 52 k:
            # docker run --rm -v ./cache:/app -w /app minidocks/inkscape -o /app/test8.svg --export-plain-svg --export-area-drawing --pdf-page 1 /app/all.pdf
            # scour -i cache/test8.svg -o cache/test9.svg  --enable-viewboxing --enable-id-stripping --enable-comment-stripping --shorten-ids --indent=none
            #
        end
        unless SKIP_SVG
            queues.each do |queue|
                fork do
                    queue.each do |info|
                        sha1 = info[0]
                        index = info[1]
                        system("docker run --rm -v ./cache:/app -w /app minidocks/inkscape -o /app/svg/#{sha1}.svg --export-plain-svg --pdf-poppler --export-area-drawing --pdf-page #{index + 1} /app/all.pdf")
                        system("scour -i \"cache/svg/#{sha1}.svg\" -o \"cache/svg-scour/#{sha1}.svg\" --enable-viewboxing --enable-id-stripping --enable-comment-stripping --shorten-ids --indent=none")
                    end
                end
            end
            cores.times { Process.wait }
        end

        @questions_for_hid['2024'] |= @questions_for_hid['2024/TN'] | @questions_for_hid['2024/TE'] | @questions_for_hid['2024/TA']
        @questions_for_hid[''] |= @questions_for_hid['2024']
        @questions_for_hid.each_pair do |k, entries|
            @questions_for_hid[k] = entries.to_a
        end
        @headings.reject! { |k, v| k[0, 6] == '2024/0' }
        @children.reject! { |k, v| k[0, 6] == '2024/0' }
        @questions_for_hid.reject! { |k, v| k[0, 6] == '2024/0' }
        @parents.reject! { |x, y| x[0, 6] == '2024/0' }
        @children['2024'].delete('2024/0')
    end

    def dump
        {
            :meta => @meta,
            :questions => @questions,
            :headings => @headings,
            :children => @children,
            :parents => @parents,
            :questions_for_hid => @questions_for_hid,
            :hid_for_question => @hid_for_question,
        }
    end
end

FileUtils::mkpath('../data')
FileUtils::mkpath('./cache/svg/')
FileUtils::mkpath('./cache/svg-scour/')

system("cp -purv ../fonts/*.ttf cache/")
parser = Parser.new()
# ['DL Technik Klasse E 2007', 'DL Technik Klasse A 2007', 'DL Betriebstechnik und Vorschriften 2007'].each do |_path|
#     path = File.join('..', 'bnetza', _path)
#     id_suffix = ''
#     id_suffix = 'E' if path.include?('Klasse E')
#     id_suffix = 'A' if path.include?('Klasse A')
#     # STDERR.puts path
#     parser.parse("#{path}/questions.xml", id_suffix)
#     Dir["#{path}/*.png"].each do |path|
#         FileUtils.cp(path, "../data/#{File.basename(path).sub('.png', id_suffix + '.png')}")
#     end
#     Dir["#{path}/*.jpg"].each do |path|
#         FileUtils.cp(path, "../data/#{File.basename(path).sub('.jpg', id_suffix + '.jpg')}")
#     end
# end
# parser.parse_darc()
parser.parse_2024()

STDERR.puts "Errors are here:"
STDERR.puts parser.faulty_keys.to_a.sort.to_yaml

parser.finalize

File.open('../data/questions.json', 'w') do |f|
    f.puts parser.dump.to_json
end

File.open('../data/questions.yaml', 'w') do |f|
    f.puts parser.dump.to_yaml
end
