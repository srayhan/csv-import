CsvImportable
=============


## Description ##

This app showcases the use of Rails Concern in implementing a generic data import from CSV files using Ruby CSV library. The CsvImportable uses Template Method design pattern. 

To make model support data import from a CSV file, just include CsvImportable.

### It has 3 overridable template methods ###

1. headers_map: Models should implement this if csv column headers are different from db column headers. It retuns a hash of csv column headers (key) to db column headers (value)

2. valid?(row):  Models should implement this if there is a way to know if the data provided is valid or not. This will avoid attempting to create a record from invalid data.

3. record_new?(row): models should implement this if want to avoid creating duplicate records.

Feel free to use it in any way you see fit. Have any suggestions to expand or improve, please let me know.

### Some ideas for future enhancement ###

1. Use of smart-csv to support more efficient bulk upload.

2. Support for updates- preferably batch. 

3. Addition of a pre and post process hooks 

#### Setup instruction ####

To setup the app, run rake db:setup
