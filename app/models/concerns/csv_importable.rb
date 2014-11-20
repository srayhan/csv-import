require 'csv'

#
# It uses Template Method pattern to create records from a csv file. 
# The methods to override: headers_map, valid?(row), record_new?(row) 
# Just include this in the model that needs to support CSV upload. 
# If csv headers match exactly the column headers in the database, don't need to override headers_map.
#
module CsvImportable
   extend ActiveSupport::Concern
      included do

      end

      module ClassMethods

         def import_from_csv(file_with_path, batch_size=100)
           CSV::HeaderConverters[:rename_headers] = lambda do |field|
               mapped_header = headers_map[field]
               raise "unknown column name- #{field}" unless mapped_header
               mapped_header
           end if headers_map.present?

           items_new = []
           items_to_update = []
           items_invalid = []
           results = []
           CSV.foreach(file_with_path, {headers: true, header_converters: :rename_headers, converters: :all, skip_blanks: true}) do |row|
             item = row.to_hash
             logger.debug("#{item}")
             if valid_record?(item)
               if record_new?(row)
                  items_new << new(item)
               else
                  items_to_update << item
               end
             else
               items_invalid << item
             end
             #let's batch them up 
             if items_new.count == batch_size
               logger.debug("creating #{items_new.inspect}")
               ActiveRecord::Base.transaction do
                  results << import(items_new)
                  items_new = []
               end
             end
           end
           #create the last batch
           #if items.present?
            ActiveRecord::Base.transaction do
              logger.debug("creating #{items_new.inspect}")
              results << import(items_new) if items_new.present?
              items_new = []
            end
           #end
           {created: results.flatten, invalid: items_invalid,  items_to_update: items_to_update}
         end

         # models should implement this if csv column headers are different from db column headers.
         # retuns a hash of csv column headers (key) to db column headers (value)
         def headers_map
            {}
         end

         # models should implement this if want to avoid creating duplicate records.  
         # 
         def record_new?(item)
            true
         end

         # Models should implement this if there is a way to know if the data provided is valid or not.  
         # This will avoid attempting to create a record from invalid data.
         def valid_record?(item)
            true
         end

      end
end