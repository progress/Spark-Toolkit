This demo project illustrates how to create Business Entities using the PDSOE wizard, and expose them
within web-based Data Object Services. This utilizes the DataObjectHandler as present in OpenEdge
11.6.3 and later. 


- Basic Wizard Usage -

1. Right-click on the project folder, select New, then Business Entity.
2. Select the package root "Minimus/PASOEContent/WEB-INF/openedge".
3. Enter a name for your new Business Entity (typically <table> + "BE").
4. Press the Next button to continue to the schema selection screen.
5. Adjust the resource name to be a simple, lowercase name (alters URL).
6. Select "CRUD and Submit" as the supported operations for this resource.
7. Select the desired database and table, or an existing schema include file.
8. Make sure the "Expose as Data Object Service" checkbox is selected.
9. Press the Finish button to generate the class and include file.


- Special Modifications -

1. Move the generated class file to the openedge/Business directory (or one of its subdirectories).
2. Move the generated schema include file to the openedge/Common directory.
3. Open the new Business Entity class file, and make the following modifications:
   3a. Add "Common/" before the name of the include filename in the schemaFile annotation property.
   3b. Make the same modification to the file include statement in the ABL code.
   3c. Adjust the class path for this file to match the subdirectory in which it resides.
   3d. Change the "inherits" class from "BusinessEntity" to "Spark.Core.Service.SparkEntity".
   3e. Remove the "define data-source" line near the top of the class (before constructor).
   3f. Alter the Constructor for this class with the following changes:

        ProDataSet = dataset <dataset_name>:handle.

        /* Data Source for each table in dataset. Should be in table order as defined in DataSet */
        extent(DataSourceArray) = 1.
        create data-source DataSourceArray[1].
        DataSourceArray[1]:add-source-buffer(buffer <db_table_name>:handle, ?).
        ProDataSource = DataSourceArray.

        /* Skip-list entries for each table in dataset. Should be in temp-table order as defined in DataSet. */
        /* Each skip-list entry is a comma-separated list of field names, to be ignored in create statement. */
        extent(SkipListArray) = 1.
        SkipListArray[1] = "".
        SkipList = SkipListArray.

    3g. Add the following annotations just above the Read method, but after the existing annotations.

        @openapi.openedge.method.property (name="mappingType", value="AFP").
        @openapi.openedge.method.property (name="capabilities", value="filter,top,skip,id,sort,orderBy").

    3h. If a submit method exists, alter the URI to be "/submit" and alias as "submit"
4. Be sure to either add the new class to an existing ABL Service, or create a new one for your PAS instance.
5. Publish the newly-generated artifacts to the server (code, .gen metadata, catalog JSON, etc.).

These changes will now support advanced features such as the mappingType (JFP and AFP plugins), and their
associated capabilities (filtering, paging, sorting, etc.) on the server side. These are all provided as
part of the SparkEntity class, which is why we inherited and adjusted our class to offer compatibility.