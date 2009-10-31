#taken from http://github.com/yob/rails/commit/986b8c99331d68087eaa0a703f4121c5c73b95ad, works around https://rails.lighthouseapp.com/projects/8994/tickets/2476-ascii-8bit-encoding-of-query-results-in-rails-232-and-ruby-191
module ActiveRecord
  module ConnectionAdapters #:nodoc:
    class Column
 
      attr_reader :charset
 
      def initialize(name, default, sql_type = nil, null = true, charset = nil)
        @name, @sql_type, @null = name, sql_type, null
        @limit, @precision, @scale = extract_limit(sql_type), extract_precision(sql_type), extract_scale(sql_type)
        @type = simplified_type(sql_type)
        @default = extract_default(default)
        @charset = charset
 
        @primary = nil
      end
    end
  end
  
  module ConnectionAdapters
    class MysqlColumn < Column #:nodoc:

      class << self

        def string_with_encoding(value, db_enc)
          return value unless value.respond_to?(:encoding)
          enc = case db_enc
            when "utf8"   then Encoding.find("UTF-8")
            when "latin1" then Encoding.find("ISO-8859-1")
          end
          
          if value.frozen?
            enc ? value.dup.force_encoding(enc) : value
          else
            enc ? value.force_encoding(enc) : value
          end
          
        end
      end

      def type_cast(value)
        if value && text?
          self.class.string_with_encoding(value, charset)
        else
          super
        end
      end

      def type_cast_code(var_name)
        if text?
          "#{self.class.name}.string_with_encoding(#{var_name}, \"#{charset}\")"
        else
          super
        end
      end
    end
    
    
    class MysqlAdapter
      # Returns the character set results will be returned in.
      def results_charset
        show_variable 'character_set_results'
      end
      
      def columns(table_name, name = nil)#:nodoc:
        sql = "SHOW FIELDS FROM #{quote_table_name(table_name)}"
        columns = []
        charset = results_charset
        result = execute(sql, name)
        result.each { |field| columns << MysqlColumn.new(field[0], field[4], field[1], field[2] == "YES", charset) }
        result.free
        columns
      end
      
    end
  end
end
