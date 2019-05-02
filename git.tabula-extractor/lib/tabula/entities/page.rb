java_import Java::TechnologyTabula::Page
java_import Java::TechnologyTabulaExtractors::BasicExtractionAlgorithm
java_import Java::TechnologyTabulaExtractors::SpreadsheetExtractionAlgorithm

class Page
  include Tabula::HasCells
  attr_accessor :file_path, :cells

  #returns a Table object
  def get_table(options={})
    options = {:vertical_rulings => []}.merge(options)

    tables = if options[:vertical_rulings].empty?
               BasicExtractionAlgorithm.new.extract(self)
             else
               BasicExtractionAlgorithm.new(options[:vertical_rulings]).extract(self)
             end

    tables.first
  end

  #for API backwards-compatibility reasons, this returns an array of arrays.
  def make_table(options={})
    get_table(options).rows
  end

  # returns the Spreadsheets; creating them if they're not memoized
  def spreadsheets(options={})
    unless @spreadsheets.nil?
      return @spreadsheets
    end
    SpreadsheetExtractionAlgorithm.new.extract(self).to_a.sort # to_a converts from java.util.ArrayList to Ruby Array
  end

  def fill_in_cells!(options={})
    spreadsheets(options).each do |spreadsheet|
      spreadsheet.cells.each do |cell|
        cell.text_elements = page.get_cell_text(cell)
      end
      spreadsheet.cells_resolved = true
    end
  end

  def number(indexing_base=:one_indexed)
    # if indexing_base == :zero_indexed
    #   return @number_one_indexed - 1
    # else
    #   return @number_one_indexed
    # end
    self.page_number
  end

  # TODO no need for this, let's choose one name
  def ruling_lines
    get_ruling_lines!
  end

  def horizontal_ruling_lines
    self.getHorizontalRulings
  end

  def vertical_ruling_lines
    self.getVerticalRulings
  end

  #returns ruling lines, memoizes them in
  def get_ruling_lines!
    self.get_rulings
  end

  def get_cell_text(area=nil)
    self.get_text(area)
  end
end

module Tabula
  Page = ::Page
end
