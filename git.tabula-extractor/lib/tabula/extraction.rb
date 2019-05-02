# -*- coding: utf-8 -*-
java_import org.apache.pdfbox.pdmodel.PDDocument
java_import org.apache.pdfbox.pdmodel.encryption.StandardDecryptionMaterial

module Tabula

  module Extraction

    def Extraction.openPDF(pdf_filename, password='')
      raise Errno::ENOENT unless File.exists?(pdf_filename)
      document = PDDocument.load(pdf_filename)
      if document.isEncrypted
        sdm = StandardDecryptionMaterial.new(password)
        document.openProtection(sdm)
      end
      document
    end

    class PagesInfoExtractor
      def initialize(pdf_filename, password='')
        @pdf_filename = pdf_filename
        @pdf_file = Extraction.openPDF(pdf_filename, password)
        @all_pages = @pdf_file.getDocumentCatalog.getAllPages
      end

      def pages
        Enumerator.new do |y|
          begin
            @all_pages.each_with_index do |page, i|
              contents = page.getContents

              y.yield Tabula::Page.new(0.to_java(:float),
                                       0.to_java(:float),
                                       page.findCropBox.width.to_java(:float),
                                       page.findCropBox.height.to_java(:float),
                                       page.getRotation.to_i.to_java(:int),
                                       (i+1).to_java(:int)) # remember, these are one-indexed
            end
          ensure
            @pdf_file.close
          end
        end
      end
    end

    class ObjectExtractor < Java::TechnologyTabula::ObjectExtractor

      alias_method :close!, :close

      # TODO: the +pages+ constructor argument does not make sense
      # now that we have +extract_page+ and +extract_pages+
      def initialize(pdf_filename, pages=[1], password='', options={})
        raise Errno::ENOENT unless File.exists?(pdf_filename)
        @pdf_filename = pdf_filename
        document = Extraction.openPDF(pdf_filename, password)

        super(document)
      end
    end
  end
end
