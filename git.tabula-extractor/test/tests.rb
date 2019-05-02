#!/usr/bin/env jruby -J-Djava.awt.headless=true
# -*- coding: utf-8 -*-
require 'minitest'
require 'minitest/autorun'
require 'csv'

require_relative '../lib/tabula'
java_import Java::TechnologyTabula::Rectangle

def table_to_array(table)
  lines_to_array(table.rows)
end

def lines_to_array(lines)
  lines.map do |l|
    l.map { |te| te.text.strip }
  end
end

def lines_to_table(lines)
  Tabula::Table.new_from_array(lines_to_array(lines))
end


# I don't want to pollute the "real" class with a funny inspect method. Just for testing comparisons.
module Tabula
  class Table
    def inspect
      getRows.map { |row| row.map(&:getText).join(",") }
      #"[" + lines.map(&:inspect).join(",") + "]"
    end
  end
end

module Tabula
  class Line
    def inspect
      @text_elements.map{|te| te.nil? ? '' : te.text}.inspect
    end
  end
end


class TestEntityComparability < Minitest::Test
  def test_text_element_comparability
    base = Tabula::TextElement.new(0, 0, 0, 0, nil, 0, "Jeremy", 0, 0)

    two = Tabula::TextElement.new(0, 0, 0, 0, nil, 0, " Jeremy  \n", 0, 0)
    three = Tabula::TextElement.new(7, 6, 8, 6, nil, 12, "Jeremy", 88, 0)
    four = Tabula::TextElement.new(5, 7, 1212, 121, nil, 15, "Jeremy", 55, 0)

    five = Tabula::TextElement.new(5, 7, 1212, 121, nil, 15, "jeremy b", 55, 0)
    six = Tabula::TextElement.new(5, 7, 1212, 121, nil, 15, "jeremy    kj", 55, 0)
    seven = Tabula::TextElement.new(0, 0, 0, 0, nil, 0, "jeremy    kj", 55, 0)
    assert_equal base, two
    assert_equal base, three
    assert_equal base, four

    refute_equal base, five
    refute_equal base, six
    refute_equal base, seven
  end

  def test_line_comparability
    text_base = Tabula::TextElement.new(0, 0, 0, 0, nil, 0, "Jeremy", 0)

    text_two = Tabula::TextElement.new(0, 0, 0, 0, nil, 0, " Jeremy  \n", 0)
    text_three = Tabula::TextElement.new(7, 6, 8, 6, nil, 12, "Jeremy", 88)
    text_four = Tabula::TextElement.new(5, 7, 1212, 121, nil, 15, "Jeremy", 55)

    text_five = Tabula::TextElement.new(5, 7, 1212, 121, nil, 15, "jeremy b", 55)
    text_six = Tabula::TextElement.new(5, 7, 1212, 121, nil, 15, "jeremy    kj", 55)
    text_seven = Tabula::TextElement.new(0, 0, 0, 0, nil, 0, "jeremy    kj", 0)
    line_base = Tabula::Line.new
    line_base.text_elements = [text_base, text_two, text_three]
    line_equal = Tabula::Line.new
    line_equal.text_elements = [text_base, text_two, text_three]
    line_equal_but_longer = Tabula::Line.new
    line_equal_but_longer.text_elements = [text_base, text_two, text_three, Tabula::TextElement::EMPTY, Tabula::TextElement::EMPTY]
    line_unequal = Tabula::Line.new
    line_unequal.text_elements = [text_base, text_two, text_three, text_five]
    line_unequal_and_longer = Tabula::Line.new
    line_unequal_and_longer.text_elements = [text_base, text_two, text_three, text_five, Tabula::TextElement::EMPTY, Tabula::TextElement::EMPTY]
    line_unequal_and_longer_and_different = Tabula::Line.new
    line_unequal_and_longer_and_different.text_elements = [text_base, text_two, text_three, text_five, Tabula::TextElement::EMPTY, 'whatever']

    assert_equal line_base, line_equal
    assert_equal line_base, line_equal_but_longer
    refute_equal line_base, line_unequal
    refute_equal line_base, line_unequal_and_longer
    refute_equal line_base, line_unequal_and_longer_and_different
  end
end

class TestPagesInfoExtractor < Minitest::Test
  def test_pages_info_extractor
    extractor = Tabula::Extraction::PagesInfoExtractor.new(File.expand_path('data/gre.pdf', File.dirname(__FILE__)))

    i = 0
    extractor.pages.each do |page|
      assert_instance_of Tabula::Page, page
      i += 1
    end
    assert_equal 2, i
  end
end

class TestDumper < Minitest::Test

  def test_extractor
    extractor = Tabula::Extraction::ObjectExtractor.new(File.expand_path('data/gre.pdf', File.dirname(__FILE__)))
    page = extractor.extract.first
    extractor.close!
    assert_instance_of Tabula::Page, page
  end

  def test_get_by_area
    extractor = Tabula::Extraction::ObjectExtractor.new(File.expand_path('data/gre.pdf', File.dirname(__FILE__)))
    page = extractor.extract.first
    characters = page.get_text(107.1, 60.10, 313.65, 291.79)
    extractor.close!
    assert_equal 151, characters.size
  end
end

class TestRulingIntersection < Minitest::Test
  def test_ruling_intersection
    horizontals = [Tabula::Ruling.new(10, 1, 10, 0)]
    verticals   = [Tabula::Ruling.new(1, 3, 0, 11),
                   Tabula::Ruling.new(1, 4, 0, 11)]
    ints = Tabula::Ruling.find_intersections(horizontals, verticals).to_a
    assert_equal 2, ints.size
    assert_equal ints[0][0].getX, 3.0
    assert_equal ints[0][0].getY, 10.0
    assert_equal ints[1][0].getX, 4.0
    assert_equal ints[1][0].getY, 10.0

    verticals =   [Tabula::Ruling.new(20, 3, 0, 11)]
    ints = Tabula::Ruling.find_intersections(horizontals, verticals).to_a
    assert_equal ints.size, 0
  end
end

class TestExtractor < Minitest::Test

  def test_extraction_of_multiple_pages
    expected_by_page = [
      [
        ["Last Name", "First Name", "Address", "City", "State", "Zip", "Occupation", "Employer", "Date", "Amount"], 
        ["Lidstad", "Dick & Peg", "62 Mississippi River Blvd N", "Saint Paul", "MN", "55104", "retired", "", "10/12/2012", "60.00"],
      ],
      [
        ["Last Name", "First Name", "Address", "City", "State", "Zip", "Occupation", "Employer", "Date", "Amount"], 
        ["Filice","Gregory A","15 Crocus Place","Saint Paul","MN","55102","Physician","Veterans Affairs Medical Cent","10/3/2012","100.00"]
      ],
        [
          ["Last Name", "First Name", "Address", "City", "State", "Zip", "Occupation", "Employer", "Date", "Amount"], 
          ["Skovolt","Glen and Anna","1473 Grantham St.","Saint Paul","MN","55108","retired","","9/12/2012","100.00"]
        ]
    ]
    (1..3).to_a.each do |page_num|

      table = table_to_array Tabula.extract_table(File.expand_path('data/strongschools.pdf', File.dirname(__FILE__)),
                                                  page_num,
                                                  [52.32857142857143,15.557142857142859,128.70000000000002,767.9571428571429],
                                                  :detect_ruling_lines => true)
      assert_equal expected_by_page[page_num-1], table[0...2]
    end
  end

  def test_extraction_of_all_pages
    extractor = Tabula::Extraction::ObjectExtractor.new(File.expand_path('data/strongschools.pdf', File.dirname(__FILE__)), :all)
    pages = extractor.extract.to_a

    expected_unique_words_per_page = ["Lidstad", "Filice", "Spencer de Gutierrez", "Mancinis", "D'Aquila"]

    pages.each_with_index do |pdf_page, idx|
      text_chunks = Tabula::TextElement.merge_words(pdf_page.texts)
      page_text_joined = text_chunks.map(&:text).join(" ")
      assert page_text_joined.include?(expected_unique_words_per_page[idx])
    end
  end

  def test_table_extraction_1
    table = table_to_array Tabula.extract_table(File.expand_path('data/gre.pdf', File.dirname(__FILE__)),
                                                1,
                                                [107.1, 57.9214, 394.5214, 290.7],
                                                :detect_ruling_lines => false,
                                                :extraction_method => 'original')

    expected = [["Prior Scale","New Scale","% Rank*"], ["800","170","99"], ["790","170","99"], ["780","170","99"], ["770","170","99"], ["760","170","99"], ["750","169","99"], ["740","169","99"], ["730","168","98"], ["720","168","98"], ["710","167","97"], ["700","166","96"], ["690","165","95"], ["680","165","95"], ["670","164","93"], ["660","164","93"], ["650","163","91"]]

    assert_equal expected, table
  end

  def test_diputados_voting_record
    table = table_to_array Tabula.extract_table(File.expand_path('data/argentina_diputados_voting_record.pdf', File.dirname(__FILE__)),
                                                1,
                                                [269.875, 12.75, 792.5, 565],
                                                :detect_ruling_lines => false)

    expected = [["ABDALA de MATARAZZO, Norma Amanda", "Frente Cívico por Santiago", "Santiago del Estero", "AFIRMATIVO"], ["ALBRIEU, Oscar Edmundo Nicolas", "Frente para la Victoria - PJ", "Rio Negro", "AFIRMATIVO"], ["ALONSO, María Luz", "Frente para la Victoria - PJ", "La Pampa", "AFIRMATIVO"], ["ARENA, Celia Isabel", "Frente para la Victoria - PJ", "Santa Fe", "AFIRMATIVO"], ["ARREGUI, Andrés Roberto", "Frente para la Victoria - PJ", "Buenos Aires", "AFIRMATIVO"], ["AVOSCAN, Herman Horacio", "Frente para la Victoria - PJ", "Rio Negro", "AFIRMATIVO"], ["BALCEDO, María Ester", "Frente para la Victoria - PJ", "Buenos Aires", "AFIRMATIVO"], ["BARRANDEGUY, Raúl Enrique", "Frente para la Victoria - PJ", "Entre Ríos", "AFIRMATIVO"], ["BASTERRA, Luis Eugenio", "Frente para la Victoria - PJ", "Formosa", "AFIRMATIVO"], ["BEDANO, Nora Esther", "Frente para la Victoria - PJ", "Córdoba", "AFIRMATIVO"], ["BERNAL, María Eugenia", "Frente para la Victoria - PJ", "Jujuy", "AFIRMATIVO"], ["BERTONE, Rosana Andrea", "Frente para la Victoria - PJ", "Tierra del Fuego", "AFIRMATIVO"], ["BIANCHI, María del Carmen", "Frente para la Victoria - PJ", "Cdad. Aut. Bs. As.", "AFIRMATIVO"], ["BIDEGAIN, Gloria Mercedes", "Frente para la Victoria - PJ", "Buenos Aires", "AFIRMATIVO"], ["BRAWER, Mara", "Frente para la Victoria - PJ", "Cdad. Aut. Bs. As.", "AFIRMATIVO"], ["BRILLO, José Ricardo", "Movimiento Popular Neuquino", "Neuquén", "AFIRMATIVO"], ["BROMBERG, Isaac Benjamín", "Frente para la Victoria - PJ", "Tucumán", "AFIRMATIVO"], ["BRUE, Daniel Agustín", "Frente Cívico por Santiago", "Santiago del Estero", "AFIRMATIVO"], ["CALCAGNO, Eric", "Frente para la Victoria - PJ", "Buenos Aires", "AFIRMATIVO"], ["CARLOTTO, Remo Gerardo", "Frente para la Victoria - PJ", "Buenos Aires", "AFIRMATIVO"], ["CARMONA, Guillermo Ramón", "Frente para la Victoria - PJ", "Mendoza", "AFIRMATIVO"], ["CATALAN MAGNI, Julio César", "Frente para la Victoria - PJ", "Tierra del Fuego", "AFIRMATIVO"], ["CEJAS, Jorge Alberto", "Frente para la Victoria - PJ", "Rio Negro", "AFIRMATIVO"], ["CHIENO, María Elena", "Frente para la Victoria - PJ", "Corrientes", "AFIRMATIVO"], ["CIAMPINI, José Alberto", "Frente para la Victoria - PJ", "Neuquén", "AFIRMATIVO"], ["CIGOGNA, Luis Francisco Jorge", "Frente para la Victoria - PJ", "Buenos Aires", "AFIRMATIVO"], ["CLERI, Marcos", "Frente para la Victoria - PJ", "Santa Fe", "AFIRMATIVO"], ["COMELLI, Alicia Marcela", "Movimiento Popular Neuquino", "Neuquén", "AFIRMATIVO"], ["CONTI, Diana Beatriz", "Frente para la Victoria - PJ", "Buenos Aires", "AFIRMATIVO"], ["CORDOBA, Stella Maris", "Frente para la Victoria - PJ", "Tucumán", "AFIRMATIVO"], ["CURRILEN, Oscar Rubén", "Frente para la Victoria - PJ", "Chubut", "AFIRMATIVO"]]

    assert_equal expected, table
  end

  def test_missing_spaces_around_an_ampersand
    pdf_file_path = File.expand_path('data/frx_2012_disclosure.pdf', File.dirname(__FILE__))
    character_extractor = Tabula::Extraction::ObjectExtractor.new(pdf_file_path)
    page_obj = character_extractor.extract.first
    lines = page_obj.ruling_lines
    vertical_rulings = lines.select(&:vertical?)

    top, left, bottom, right = [170, 28, 185, 833] #top left bottom right

    expected = Tabula::Table.new_from_array([
       ["", "REGIONAL PULMONARY & SLEEP",],
       ["AARON, JOSHUA, N", "", "WEST GROVE, PA", "SPEAKING FEES", "$4,700.00"],
       ["", "MEDICINE", ],
      ])

    assert_equal expected, lines_to_table(page_obj.get_area(top,left,bottom,right).make_table(:vertical_rulings => vertical_rulings))
    character_extractor.close!
  end

  # TODO Spaces inserted in words - fails
  def test_bo_page24
    table = table_to_array Tabula.extract_table(File.expand_path('data/bo_page24.pdf', File.dirname(__FILE__)),
                                                1,
                                                [425.625, 53.125, 575.714, 810.535],
                                                :detect_ruling_lines => false)

    expected = [["1", "UNICA", "CECILIA KANDUS", "16/12/2008", "PEDRO ALBERTO GALINDEZ", "60279/09"], ["1", "UNICA", "CECILIA KANDUS", "10/06/2009", "PASTORA FILOMENA NAVARRO", "60280/09"], ["13", "UNICA", "MIRTA S. BOTTALLO DE VILLA", "02/07/2009", "MARIO LUIS ANGELERI, DNI 4.313.138", "60198/09"], ["16", "UNICA", "LUIS PEDRO FASANELLI", "22/05/2009", "PETTER o PEDRO KAHRS", "60244/09"], ["18", "UNICA", "ALEJANDRA SALLES", "26/06/2009", "RAUL FERNANDO FORTINI", "60236/09"], ["31", "UNICA", "MARÍA CRISTINA GARCÍA", "17/06/2009", "DOMINGO TRIPODI Y PAULA LUPPINO", "60302/09"], ["34", "UNICA", "SUSANA B. MARZIONI", "11/06/2009", "JESUSA CARMEN VAZQUEZ", "60177/09"], ["51", "UNICA", "MARIA LUCRECIA SERRAT", "19/05/2009", "DANIEL DECUADRO", "60227/09"], ["51", "UNICA", "MARIA LUCRECIA SERRAT", "12/02/2009", "ELIZABETH LILIANA MANSILLA ROMERO", "60150/09"], ["75", "UNICA", "IGNACIO M. REBAUDI BASAVILBASO", "01/07/2009", "ABALSAMO ALFREDO DANIEL", "60277/09"], ["94", "UNICA", "GABRIELA PALÓPOLI", "02/07/2009", "ALVAREZ ALICIA ESTHER", "60360/09"], ["96", "UNICA", "DANIEL PAZ EYNARD", "16/06/2009", "NELIDA ALBORADA ALCARAZ SERRANO", "60176/09"]]

    assert_equal expected, table
  end


  def test_vertical_rulings_splitting_words
    #if a vertical ruling crosses over a word, the word should be split at that vertical ruling
    # before, the entire word would end up on one side of the vertical ruling.
    pdf_file_path = File.expand_path('data/vertical_rulings_bug.pdf', File.dirname(__FILE__))

    #both of these are semantically "correct"; the difference is in how we handle multi-line cells
    expected = Tabula::Table.new_from_array([
      ["ABRAHAMS, HARRISON M", "ARLINGTON", "TX", "HARRISON M ABRAHAMS", "", "", "$3.08", "", "", "$3.08"],
      ["ABRAHAMS, ROGER A", "MORGANTOWN", "WV", "ROGER A ABRAHAMS", "", "$1500.00", "$76.28", "$49.95", "", "$1626.23"],
      ["ABRAHAMSON, TIMOTHY GARTH", "URBANDALE", "IA", "TIMOTHY GARTH ABRAHAMSON", "", "", "$22.93", "", "", "$22.93"]
     ])
    other_expected = Tabula::Table.new_from_array([
      ["ABRAHAMS, HARRISON M", "ARLINGTON", "TX", "HARRISON M ABRAHAMS", "", "", "$3.08", "", "", "$3.08"],
      ["ABRAHAMS, ROGER A", "MORGANTOWN", "WV", "ROGER A ABRAHAMS", "", "$1500.00", "$76.28", "$49.95", "", "$1626.23"],
      ["ABRAHAMSON, TIMOTHY GARTH", "URBANDALE", "IA", "TIMOTHY GARTH", "", "", "$22.93", "", "", "$22.93"],
      ["", "", "", "ABRAHAMSON"]
     ])

    #N.B. it's "MORGANTOWN", "WV" that we're most interested in here (it used to show up as ["MORGANTOWNWV", "", ""])


    extractor = Tabula::Extraction::ObjectExtractor.new(pdf_file_path, 1...2) #:all ) # 1..2643
    extractor.extract.each_with_index do |pdf_page, page_index|

      page_areas = [[250, 0, 325, 1700]]

      scale_factor = pdf_page.width / 1700

      vertical_rulings = [0, 360, 506, 617, 906, 1034, 1160, 1290, 1418, 1548].map{ |n| Tabula::Ruling.new(0, n * scale_factor, 0, 1000)}

      tables = page_areas.map do |page_area|
        pdf_page.get_area(*page_area).make_table(:vertical_rulings => vertical_rulings)
      end
      assert_equal expected, lines_to_table(tables.first)
    end
    extractor.close!
  end

  def test_vertical_rulings_prevent_merging_of_columns
    expected = [["SZARANGOWICZ", "GUSTAVO ALEJANDRO", "25.096.244", "20-25096244-5", "09/10/2013", "EFECTIVO", "$ 10.000,00"], ["TAILHADE", "LUIS RODOLFO", "21.386.299", "20-21386299-6", "09/10/2013", "EFECTIVO", "$ 10.000,00"], ["TEDESCHI", "ADRIÁN ALBERTO", "24.171.507", "20-24171507-9", "09/10/2013", "EFECTIVO", "$ 10.000,00"], ["URRIZA", "MARÍA TERESA", "18.135.604", "27-18135604-4", "09/10/2013", "EFECTIVO", "$ 10.000,00"], ["USTARROZ", "GERÓNIMO JAVIER", "24.912.947", "20-24912947-0", "09/10/2013", "EFECTIVO", "$ 10.000,00"], ["VALSANGIACOMO BLANC", "OFERNANDO JORGE", "26.800.203", "20-26800203-1", "09/10/2013", "EFECTIVO", "$ 10.000,00"], ["VICENTE", "PABLO ARIEL", "21.897.586", "20-21897586-1", "09/10/2013", "EFECTIVO", "$ 10.000,00"], ["AMBURI", "HUGO ALBERTO", "14.096.560", "20-14096560-0", "09/10/2013", "EFECTIVO", "$ 20.000,00"], ["BERRA", "CLAUDIA SUSANA", "14.433.112", "27-14433112-0", "09/10/2013", "EFECTIVO", "$ 10.000,00"]]

    vertical_rulings = [ 147, 256, 310, 375, 431, 504].map{ |n| Tabula::Ruling.new(0, n, 0, 1000) }

    table = table_to_array Tabula.extract_table(File.expand_path('data/campaign_donors.pdf', File.dirname(__FILE__)),
                                                1,
                                                [255.57,40.43,398.76,557.35],
                                                :vertical_rulings => vertical_rulings)

    assert_equal expected, table
  end

  def test_get_spacing_and_merging_right
    table = table_to_array Tabula.extract_table(File.expand_path('data/strongschools.pdf', File.dirname(__FILE__)),
                                                1,
                                                [52.32857142857143,15.557142857142859,128.70000000000002,767.9571428571429],
                                                :detect_ruling_lines => true)

    expected = [["Last Name", "First Name", "Address", "City", "State", "Zip", "Occupation", "Employer", "Date", "Amount"], ["Lidstad", "Dick & Peg", "62 Mississippi River Blvd N", "Saint Paul", "MN", "55104", "retired", "", "10/12/2012", "60.00"], ["Strom", "Pam", "1229 Hague Ave", "St. Paul", "MN", "55104", "", "", "9/12/2012", "60.00"], ["Seeba", "Louise & Paul", "1399 Sheldon St", "Saint Paul", "MN", "55108", "BOE", "City of Saint Paul", "10/12/2012", "60.00"], ["Schumacher / Bales", "Douglas L. / Patricia", "948 County Rd. D W", "Saint Paul", "MN", "55126", "", "", "10/13/2012", "60.00"], ["Abrams", "Marjorie", "238 8th St east", "St Paul", "MN", "55101", "Retired", "Retired", "8/8/2012", "75.00"], ["Crouse / Schroeder", "Abigail / Jonathan", "1545 Branston St.", "Saint Paul", "MN", "55108", "", "", "10/6/2012", "75.00"]]

    assert_equal expected, table

  end


  class SpreadsheetsHasCellsTester
    include Tabula::HasCells
    attr_accessor :cells
    def initialize(cells)
      @cells = cells
    end
  end

  class CellsHasCellsTester
    include Tabula::HasCells
    attr_accessor :vertical_ruling_lines, :horizontal_ruling_lines, :cells
    def initialize(vertical_ruling_lines, horizontal_ruling_lines)
      @cells = []
      @vertical_ruling_lines = vertical_ruling_lines
      @horizontal_ruling_lines = horizontal_ruling_lines
      find_cells!(horizontal_ruling_lines, vertical_ruling_lines)
    end
  end

  #just tests the algorithm
  def test_lines_to_cells
    vertical_ruling_lines = [ Tabula::Ruling.new(40.0, 18.0, 0.0, 40.0),
                              Tabula::Ruling.new(44.0, 70.0, 0.0, 36.0),
                              Tabula::Ruling.new(40.0, 226.0, 0.0, 40.0)]

    horizontal_ruling_lines = [ Tabula::Ruling.new(40.0, 18.0, 208.0, 0.0),
                                Tabula::Ruling.new(44.0, 18.0, 208.0, 0.0),
                                Tabula::Ruling.new(50.0, 18.0, 208.0, 0.0),
                                Tabula::Ruling.new(54.0, 18.0, 208.0, 0.0),
                                Tabula::Ruling.new(60.0, 18.0, 208.0, 0.0),
                                Tabula::Ruling.new(64.0, 18.0, 208.0, 0.0),
                                Tabula::Ruling.new(70.0, 18.0, 208.0, 0.0),
                                Tabula::Ruling.new(74.0, 18.0, 208.0, 0.0),
                                Tabula::Ruling.new(80.0, 18.0, 208.0, 0.0)]

    expected_cells = [Tabula::Cell.new(40.0, 18.0, 208.0, 4.0), Tabula::Cell.new(44.0, 18.0, 52.0, 6.0),
                      Tabula::Cell.new(50.0, 18.0, 52.0, 4.0), Tabula::Cell.new(54.0, 18.0, 52.0, 6.0),
                      Tabula::Cell.new(60.0, 18.0, 52.0, 4.0), Tabula::Cell.new(64.0, 18.0, 52.0, 6.0),
                      Tabula::Cell.new(70.0, 18.0, 52.0, 4.0), Tabula::Cell.new(74.0, 18.0, 52.0, 6.0),
                      Tabula::Cell.new(44.0, 70.0, 156.0, 6.0), Tabula::Cell.new(50.0, 70.0, 156.0, 4.0),
                      Tabula::Cell.new(54.0, 70.0, 156.0, 6.0), Tabula::Cell.new(60.0, 70.0, 156.0, 4.0),
                      Tabula::Cell.new(64.0, 70.0, 156.0, 6.0), Tabula::Cell.new(70.0, 70.0, 156.0, 4.0),
                      Tabula::Cell.new(74.0, 70.0, 156.0, 6.0), ]

    actual_cells = CellsHasCellsTester.new(vertical_ruling_lines, horizontal_ruling_lines).cells
    assert_equal Set.new(expected_cells), Set.new(actual_cells) #I don't care about order
  end

  #this is the real deal!!
  def test_extract_tabular_data_using_lines_and_spreadsheets
    pdf_file_path = File.expand_path('data/frx_2012_disclosure.pdf', File.dirname(__FILE__))
    expected_data_path = File.expand_path('data/frx_2012_disclosure.tsv', File.dirname(__FILE__))
    expected = open(expected_data_path, 'r').read

    extractor = Tabula::Extraction::ObjectExtractor.new(pdf_file_path, :all)
    extractor.extract.each do |pdf_page|
      spreadsheet = pdf_page.spreadsheets.first
      assert_equal expected, spreadsheet.to_tsv
    end
    extractor.close!
  end

  def test_cope_with_a_tableless_page
    skip("line_color_filter unimplemented in tabula-java for now, see https://github.com/tabulapdf/tabula-java/issues/21")
    pdf_file_path = File.expand_path('data/no_tables.pdf', File.dirname(__FILE__))

    extractor = Tabula::Extraction::ObjectExtractor.new(pdf_file_path, :all, '',
                                                        :line_color_filter => lambda{|components| components.all?{|c| c < 0.1}}
                                                       )
    spreadsheets = extractor.extract.to_a.first.spreadsheets
    extractor.close!
    assert_equal 0, spreadsheets.size
  end

  def test_spanning_cells
    pdf_file_path = File.expand_path('data/spanning_cells.pdf', File.dirname(__FILE__))
    expected_data_path = File.expand_path('data/spanning_cells.csv', File.dirname(__FILE__))
    expected = open(expected_data_path, 'r').read
    extractor = Tabula::Extraction::ObjectExtractor.new(pdf_file_path, [1])
    extractor.extract.each do |pdf_page|
      spreadsheet = pdf_page.spreadsheets.first
      assert_equal expected, spreadsheet.to_csv
    end
    extractor.close!
  end

  def test_almost_vertical_lines
    pdf_file_path = File.expand_path('data/puertos1.pdf', File.dirname(__FILE__))
    top, left, bottom, right = 273.9035714285714, 30.32142857142857, 554.8821428571429, 546.7964285714286
    area = Rectangle.new(top, left,
                         right - left, bottom - top)

    extractor = Tabula::Extraction::ObjectExtractor.new(pdf_file_path, [1])
    extractor.extract.each do |pdf_page|
      rulings = Tabula::Ruling.crop_rulings_to_area(pdf_page.ruling_lines, area)
      # TODO assertion not entirely correct, should do the trick for now
      assert_equal 15, rulings.select(&:vertical?).count
    end
    extractor.close!
  end

  def test_extract_spreadsheet_within_an_area
    pdf_file_path = File.expand_path('data/puertos1.pdf', File.dirname(__FILE__))
    top, left, bottom, right = 273.9035714285714,30.32142857142857,554.8821428571429,546.7964285714286

    extractor = Tabula::Extraction::ObjectExtractor.new(pdf_file_path, [1])
    pdf_page = extractor.extract.first

    area = pdf_page.get_area(top, left, bottom, right)
    table = area.spreadsheets.first.getRows.map { |r| r.map(&:getText) }

    assert_equal 15, table.length
    assert_equal ["", "TM", "M.U$S", "TM", "M.U$S", "TM", "M.U$S", "TM", "M.U$S", "TM", "M.U$S", "TM", "M.U$S", "TM"], table.first
    assert_equal ["TOTAL", "453,515", "895,111", "456,431", "718,382", "487,183", "886,211", "494,220", "816,623", "495,580", "810,565", "627,469", "1,248,804", "540,367"], table.last

    extractor.close!
  end

  def test_remove_repeated_text
    top, left, bottom, right = 101.82857142857144,48.08571428571429,497.8285714285715,765.1285714285715

    table = Tabula.extract_table(File.expand_path('data/nyc_2013fiscalreporttables.pdf', File.dirname(__FILE__)),
                                 1,
                                 [top,left,bottom,right],
                                 :detect_ruling_lines => false,
                                 :extraction_method => 'original')

    ary = table_to_array(table)

    assert_equal "$ 18,969,610", ary[1][1]
    assert_equal "$ 18,157,722", ary[1][2]
  end

  def test_remove_overlapping_text
    # one of those PDFs that put characters on top of another to make text "bold"
    top,left,bottom,right = 399.98571428571427,36.06428571428571,425.1214285714285,544.2428571428571
    table = Tabula.extract_table(File.expand_path('data/wc2012.pdf', File.dirname(__FILE__)),
                                 1,
                                 [top,left,bottom,right],
                                 :detect_ruling_lines => false,
                                 :extraction_method => 'original')

    ary = table_to_array(table)
    assert_equal ary.first.first, "Community development"
  end

  def test_cells_including_line_returns
    data = []
    pdf_file_path = File.expand_path('data/sydney_disclosure_contract.pdf', File.dirname(__FILE__))
    extractor = Tabula::Extraction::ObjectExtractor.new(pdf_file_path, [1])
    extractor.extract([1.to_java(:int)]).each do |pdf_page|
      pdf_page.spreadsheets.each do |spreadsheet|
        spreadsheet.cells.each do |cell|

          # this pattern is deprecated and maintained only for backwards-compatibility. please don't copy it.
          # data << cell.text(true) would be sufficient in modern Tabula for all three following lines.
          cell.options = ({:use_line_returns => true, :cell_debug => 0})
          data << cell.text
        end
      end
    end
    extractor.close!
    expected = ["1295", "Name: Reino International Pty Ltd trading as Duncan Solutions \rAddress: 15/39 Herbet Street, St Leonards NSW 2065", "N/A", "Effective Date: 13 May 2013 \rDuration: 15 Weeks", "Supply, Installation and Maintenance of Parking Ticket Machines", "$3,148,800.00exgst", "N/A", "N/A", "Open Tender  \rTender evaluation criteria included: \r- The schedule of prices \r- Compliance with technical specifications/Technical assessment \r- Operational Plan including maintenance procedures"]
    assert_equal expected, data
  end

  def test_remove_repeated_spaces
    top,left,bottom,right = 304.9375,78.625,334.6875,501.5
    table = Tabula.extract_table(File.expand_path('data/repeated_spaces.pdf', File.dirname(__FILE__)),
                                 1,
                                 [top,left,bottom,right],
                                 :detect_ruling_lines => false,
                                 :extraction_method => 'original')

    table_to_array(table).each { |row|
      assert_equal row.size, 7
    }
  end

  def test_monospaced_table
    top,left,bottom,right = 149.9142857142857, 89.10000000000001, 243.25714285714287, 721.2857142857143
    table = Tabula.extract_table(File.expand_path('data/monospaced1.pdf', File.dirname(__FILE__)),
                                 1,
                                 [top,left,bottom,right],
                                 :detect_ruling_lines => false,
                                 :extraction_method => 'original')

    expected = [["ALBERT LEA, MAYO CLINIC HEALTH SYS- ALBE", "0", "0", "0", "7", "7", ".0", ".0", ".0", "23.3", "10.4"], ["ROCHESTER, MAYO CLINIC METHODIST HOSPITA", "6", "7", "14", "11", "25", "27.3", "100.0", "37.8", "36.7", "37.3"], ["ROCHESTER, MAYO CLINIC ST. MARYS", "9", "0", "11", "7", "18", "40.9", ".0", "29.7", "23.3", "26.9"], ["BLUE EARTH, UNITED HOSPITAL DISTRICT", "3", "0", "4", "0", "4", "13.6", ".0", "10.8", ".0", "6.0"], ["FAIRMONT, MAYO CLINIC HEALTH SYSTEM -FAI", "1", "0", "2", "1", "3", "4.5", ".0", "5.4", "3.3", "4.5"], ["MANKATO, MAYO CLINIC HEALTH SYSTEM- MANK", "3", "0", "5", "3", "8", "13.6", ".0", "13.5", "10.0", "11.9"], ["ALL REGION 4 (TC) HOSPITALS", "0", "0", "1", "1", "2", ".0", ".0", "2.7", "3.3", "3.0"], ["", "22", "7", "37", "30", "67", "100.0", "100.0", "100.0", "100.0", "100.0"]]
    assert_equal expected, table_to_array(table)
  end

  def test_monospaced_table_ascii_line_separator
    extractor = Tabula::Extraction::ObjectExtractor.new(File.expand_path('data/monospaced_ascii_sep.pdf', File.dirname(__FILE__)),
                                                        [1])
    expected = [["Column A", "* ColB1", "ColB2  ColB3", "* Column C"], ["Value 1", "*  23.5", "66.811.0", "* Name 1"], ["Value 2", "*  33.2", "56.312.0", "* Name 2"], ["Value 3", "* 123.3", "200.4  123.9", "* Name 3"], ["Value 4", "*  24.5", "66.811.0", "* Name 1"], ["Value 5", "*  43.2", "80.114.5", "* Name 2"], ["Value 6", "* 100.6", "190.4  120.3", "* Name 3"], ["Value 7", "*  11.5", "66.811.0", "* Name 1"], ["Value 8", "*  37.4", "77.420.1", "* Name 2"], ["Value 9", "* 883.3", "110.4  111.2", "* Name 3"]]

    table = extractor.extract_page(1).get_table
    assert_equal expected, table_to_array(table)
  end


  def test_bad_column_detection
    top,left,bottom,right = 535.5,70.125,549.3125,532.3125
    table = Tabula.extract_table(File.expand_path('data/indecago10.pdf', File.dirname(__FILE__)),
                                 1,
                                 [top,left,bottom,right],
                                 :detect_ruling_lines => false,
                                 :extraction_method => 'original')

    assert_equal ["Comunicaciones", "104,29", "– –", "0,1", "0,6", "1,1", "0,3"],
                 table_to_array(table).first

  end

  def test_character_merging_that_wasnt_working_previously
    expected_data_path = File.expand_path('data/french1.tsv', File.dirname(__FILE__))
    expected = CSV.read(expected_data_path, { :col_sep => "\t" })
    expected.map! { |r| r.map(&:strip) }

    top,left,bottom,right = 32.87142857142857,41.72142857142857,486.75,694.0928571428572
    table = Tabula.extract_table(File.expand_path('data/french1.pdf', File.dirname(__FILE__)),
                                 1,
                                 [top,left,bottom,right],
                                 :detect_ruling_lines => false,
                                 :extraction_method => 'original')

    assert_equal expected, table_to_array(table)
  end

  def test_issue78_some_ruling_lines_not_detected
    pdf_file_path = File.expand_path('data/mineria.pdf', File.dirname(__FILE__))
    area = [104.46890818740722, 13, 580.548646927163, 820.8271357581996]
    table = Tabula.extract_table(File.expand_path('data/mineria.pdf',
                                                  File.dirname(__FILE__)),
                                 1,
                                 area,
                                 :extraction_method => 'spreadsheet')
    expected = [["1", "010000091", "086", "03/12/2012", "ACHAYAP MANTU ALDO", "ACHAYAP MANTU ALDO", "1", "OTROS", ".", ".", "AMAZONAS", "CONDORCANQ\rUI", "NIEVA", "", "", ""], ["2", "010000023", "022", "18/06/2012", "ACOSTA ROSALES YOSELIN BRICET", "ACOSTA ROSALES YOSELIN \rBRICET", "2", "TITULAR", "NANCY 11   ( REGISTRO \rCANCELADO )", "510001910", "AMAZONAS", "BONGARA", "FLORIDA", "18", "9,357,000", "174,000"]]
    assert expected, table_to_array(table)[0..2]
  end


  def test_checks_for_text_on_page
    pdf_file_path = File.expand_path('data/gretna-owh-request.pdf', File.dirname(__FILE__))
    extractor = Tabula::Extraction::ObjectExtractor.new(pdf_file_path, [1])
    extractor.extract.each do |pdf_page|
      assert !pdf_page.has_text?
    end
    extractor.close!

    pdf_file_path = File.expand_path('data/brazil_crop_area.pdf', File.dirname(__FILE__))
    extractor = Tabula::Extraction::ObjectExtractor.new(pdf_file_path, [1])
    extractor.extract.each do |pdf_page|
      assert pdf_page.has_text?
    end
    extractor.close!
  end

  def test_spanning_cells
    # see
    # https://github.com/tabulapdf/tabula-java/issues/55
    # https://github.com/tabulapdf/tabula-extractor/commit/735b82450a40b3743333816b50cad470b1ca7b43#commitcomment-15087511
    # this PDF is a printout of an Excel spreadsheet that has "spanning cells", that is, 10 or so data columns
    # with six header cells -- some of the header cells are "merged" to span over several data columns.
    # we cope with this internally by creating zero-width (or zero-height for cells that span rows) cells
    # and in array/CSV output, these blank cells are inserted /after/ the text of the real cell.
    pdf_file_path = File.expand_path("data/47008204D_USA.page4.pdf", File.dirname(__FILE__))
    extractor = Tabula::Extraction::ObjectExtractor.new(pdf_file_path)
    pdf_page = extractor.extract.first
    actual_header_row = table_to_array(pdf_page.spreadsheets.first).first
    expected_header_row = ["", "", "", "IEM Findings","","","","","", "Remediation","","","", "[Status]"]
    assert_equal expected_header_row, actual_header_row
  end
end

class TestIsTabularHeuristic < Minitest::Test

  EXPECTED_TO_BE_SPREADSHEET = ['GSK_2012_Q4.page437.pdf', 'strongschools.pdf', 'tabla_subsidios.pdf']
  #NOT_EXPECTED_TO_BE_SPREADSHEET = ['560015757GV_China.page1.pdf', 'S2MNCEbirdisland.pdf', 'bo_page24.pdf', 'campaign_donors.pdf']
  NOT_EXPECTED_TO_BE_SPREADSHEET = ['47008204D_USA.page4.pdf', '560015757GV_China.page1.pdf', 'bo_page24.pdf', 'campaign_donors.pdf']

  File.expand_path('data/frx_2012_disclosure.pdf', File.dirname(__FILE__))

  def test_heuristic_detects_spreadsheets
    EXPECTED_TO_BE_SPREADSHEET.each do |f|
      path = File.expand_path('data/' + f, File.dirname(__FILE__))
      extractor = Tabula::Extraction::ObjectExtractor.new(path, [1])
      page = extractor.extract.first
      page.get_ruling_lines!
      extractor.close!
      assert page.is_tabular?, "failed on file #{f}"
    end
  end

  def test_heuristic_detects_non_spreadsheets
    NOT_EXPECTED_TO_BE_SPREADSHEET.each do |f|
      path = File.expand_path('data/' + f, File.dirname(__FILE__))
      extractor = Tabula::Extraction::ObjectExtractor.new(path, [1])
      page = extractor.extract.first
      page.get_ruling_lines!
      extractor.close!
      assert !page.is_tabular?, "failed on file #{f}"
    end
  end

end
